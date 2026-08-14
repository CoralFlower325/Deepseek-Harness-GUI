import Foundation

@MainActor
final class RuntimeManager: ObservableObject {
    @Published private(set) var state: RuntimeState
    @Published private(set) var latestVersion: String?
    @Published private(set) var isChecking = false
    @Published private(set) var isInstalling = false
    @Published private(set) var statusMessage = ""

    let paths: HarnessPaths

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    init() throws {
        paths = try HarnessPaths()
        state = Self.loadState(from: paths.stateURL)

        if state.active == nil, let seed = Self.descriptor(at: paths.seedRuntimeRoot, isSeed: true) {
            state.active = seed.version
            try saveState()
        }
    }

    var activeVersion: String? { state.active }
    var pendingVersion: String? { state.pending }
    var previousVersion: String? { state.previous }

    func activeRuntime() -> RuntimeDescriptor? {
        guard let version = state.active else { return nil }
        return runtime(version: version)
    }

    func pendingRuntime() -> RuntimeDescriptor? {
        guard let version = state.pending else { return nil }
        return runtime(version: version)
    }

    func previousRuntime() -> RuntimeDescriptor? {
        guard let version = state.previous else { return nil }
        return runtime(version: version)
    }

    func runtime(version: String) -> RuntimeDescriptor? {
        let external = paths.runtimeRoot(for: version)
        if let descriptor = Self.descriptor(at: external, isSeed: false), descriptor.version == version {
            return descriptor
        }
        if let seed = Self.descriptor(at: paths.seedRuntimeRoot, isSeed: true), seed.version == version {
            return seed
        }
        return nil
    }

    func commitPending() throws {
        guard let pending = state.pending else { return }
        state.previous = state.active
        state.active = pending
        state.pending = nil
        try saveState()
        statusMessage = "已启用 Harness \(pending)"
    }

    func discardPending() throws {
        let failedVersion = state.pending
        state.pending = nil
        try saveState()
        if let failedVersion {
            statusMessage = "Harness \(failedVersion) 未启用，仍使用原版本"
        }
    }

    func promotePrevious() throws {
        guard let previous = state.previous else { return }
        let current = state.active
        state.active = previous
        state.previous = current
        state.pending = nil
        try saveState()
        statusMessage = "当前运行版本已切换为 \(previous)"
    }

    func checkForUpdates(installAutomatically: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "正在查询 npm registry…"

        Task {
            do {
                let url = URL(string: "https://registry.npmjs.org/@deepseek-ai%2Fdsh/latest")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let release = try JSONDecoder().decode(LatestRelease.self, from: data)
                latestVersion = release.version

                if release.version == state.active {
                    statusMessage = "当前已是最新版 \(release.version)"
                } else {
                    statusMessage = "发现 Harness \(release.version)"
                    if installAutomatically {
                        install(version: release.version)
                    }
                }
            } catch {
                statusMessage = "查询更新失败：\(error.localizedDescription)"
            }
            isChecking = false
        }
    }

    func installLatest() {
        guard let latestVersion else {
            checkForUpdates()
            return
        }
        install(version: latestVersion)
    }

    func install(version: String) {
        guard !isInstalling else { return }
        isInstalling = true
        statusMessage = "正在安装 Harness \(version)…"

        let paths = self.paths
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Self.performInstall(version: version, paths: paths)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isInstalling = false
                switch result {
                case .success:
                    self.state.pending = version
                    do {
                        try self.saveState()
                        self.statusMessage = "Harness \(version) 已下载，将在启用后成为当前版本"
                    } catch {
                        self.statusMessage = "保存待启用版本失败：\(error.localizedDescription)"
                    }
                case .failure(let error):
                    self.statusMessage = "安装失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func saveState() throws {
        let data = try encoder.encode(state)
        try data.write(to: paths.stateURL, options: .atomic)
    }

    private static func loadState(from url: URL) -> RuntimeState {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(RuntimeState.self, from: data)
        else {
            return .empty
        }
        return state
    }

    nonisolated private static func descriptor(at root: URL, isSeed: Bool) -> RuntimeDescriptor? {
        let packageURL = root.appendingPathComponent("node_modules/@deepseek-ai/dsh/package.json")
        guard let data = try? Data(contentsOf: packageURL),
              let package = try? JSONDecoder().decode(DshPackage.self, from: data),
              let relativeEntry = package.bin["dsh"]
        else {
            return nil
        }

        let entryURL = packageURL
            .deletingLastPathComponent()
            .appendingPathComponent(relativeEntry)
        guard FileManager.default.fileExists(atPath: entryURL.path) else { return nil }

        return RuntimeDescriptor(
            version: package.version,
            rootURL: root,
            entryURL: entryURL,
            isBundledSeed: isSeed
        )
    }

    nonisolated private static func performInstall(version: String, paths: HarnessPaths) -> Result<Void, Error> {
        do {
            let fileManager = FileManager.default
            guard fileManager.isExecutableFile(atPath: paths.bundledNodeURL.path) else {
                throw RuntimeError.missingEngine(paths.bundledNodeURL.path)
            }
            guard fileManager.fileExists(atPath: paths.bundledNpmCLIURL.path) else {
                throw RuntimeError.missingNpm(paths.bundledNpmCLIURL.path)
            }

            let destination = paths.runtimeRoot(for: version)
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
            fileManager.createFile(atPath: paths.updateLogURL.path, contents: nil)
            let log = try FileHandle(forWritingTo: paths.updateLogURL)
            defer { try? log.close() }

            let process = Process()
            process.executableURL = paths.bundledNodeURL
            process.arguments = [
                paths.bundledNpmCLIURL.path,
                "install",
                "--prefix", destination.path,
                "@deepseek-ai/dsh@\(version)",
                "--omit=dev",
                "--no-audit",
                "--no-fund",
                "--dangerously-allow-all-scripts",
            ]
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = paths.bundledNodeBinDirectory.path + ":" + (environment["PATH"] ?? "")
            process.environment = environment
            process.standardOutput = log
            process.standardError = log

            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw RuntimeError.npmFailed(process.terminationStatus, paths.updateLogURL.path)
            }
            guard let installed = descriptor(at: destination, isSeed: false), installed.version == version else {
                throw RuntimeError.missingInstalledRuntime(version)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

private struct LatestRelease: Decodable {
    let version: String
}

private struct DshPackage: Decodable {
    let version: String
    let bin: [String: String]
}

private enum RuntimeError: LocalizedError {
    case missingEngine(String)
    case missingNpm(String)
    case npmFailed(Int32, String)
    case missingInstalledRuntime(String)

    var errorDescription: String? {
        switch self {
        case .missingEngine(let path):
            return "找不到内置 Node：\(path)"
        case .missingNpm(let path):
            return "找不到内置 npm：\(path)"
        case .npmFailed(let status, let log):
            return "npm 退出码 \(status)，日志：\(log)"
        case .missingInstalledRuntime(let version):
            return "npm 完成后未找到 Harness \(version)"
        }
    }
}
