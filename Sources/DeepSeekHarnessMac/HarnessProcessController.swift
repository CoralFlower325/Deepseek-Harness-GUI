import Foundation

@MainActor
final class HarnessProcessController {
    private var process: Process?
    private var outputPipe: Pipe?
    private var intentionalStop = false
    private var emittedReadyURL = false
    nonisolated(unsafe) private var bufferedText = ""
    private let outputQueue = DispatchQueue(label: "DeepSeekHarnessMac.process-output")

    var isRunning: Bool { process?.isRunning == true }

    func start(
        runtime: RuntimeDescriptor,
        nodeURL: URL,
        nodeBinDirectory: URL,
        dshHome: URL,
        workspace: URL,
        onLog: @escaping (String) -> Void,
        onReady: @escaping (URL) -> Void,
        onExit: @escaping (_ status: Int32, _ wasIntentional: Bool, _ reachedReady: Bool) -> Void
    ) throws {
        guard process == nil else { return }

        intentionalStop = false
        emittedReadyURL = false
        bufferedText = ""

        let process = Process()
        let pipe = Pipe()
        process.executableURL = nodeURL
        process.arguments = [
            runtime.entryURL.path,
            "web",
            "--host", "127.0.0.1",
            "--port", "0",
        ]
        process.currentDirectoryURL = workspace

        var environment = ProcessInfo.processInfo.environment
        environment["DSH_HOME"] = dshHome.path
        environment["PATH"] = nodeBinDirectory.path + ":" + (environment["PATH"] ?? "")
        process.environment = environment
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(decoding: data, as: UTF8.self)
            self?.consume(text, onLog: onLog, onReady: onReady)
        }

        process.terminationHandler = { [weak self] terminated in
            DispatchQueue.main.async {
                guard let self else { return }
                pipe.fileHandleForReading.readabilityHandler = nil
                let wasIntentional = self.intentionalStop
                let reachedReady = self.emittedReadyURL
                self.process = nil
                self.outputPipe = nil
                onExit(terminated.terminationStatus, wasIntentional, reachedReady)
            }
        }

        self.process = process
        self.outputPipe = pipe
        do {
            try process.run()
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            self.process = nil
            self.outputPipe = nil
            throw error
        }
    }

    func stop() async {
        guard let process else { return }
        intentionalStop = true
        if process.isRunning {
            process.terminate()
        }
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }

    private nonisolated func consume(
        _ text: String,
        onLog: @escaping (String) -> Void,
        onReady: @escaping (URL) -> Void
    ) {
        outputQueue.sync {
            bufferedText.append(text)
            while let newline = bufferedText.firstIndex(of: "\n") {
                let line = String(bufferedText[..<newline]).trimmingCharacters(in: .newlines)
                bufferedText.removeSubrange(...newline)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    onLog(line)
                    guard !self.emittedReadyURL,
                          let marker = line.range(of: "dsh web: ")
                    else { return }

                    let suffix = line[marker.upperBound...]
                    guard let token = suffix.split(separator: " ").first,
                          let url = URL(string: String(token))
                    else { return }
                    self.emittedReadyURL = true
                    onReady(url)
                }
            }
        }
    }
}
