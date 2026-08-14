import Foundation

@MainActor
final class RuntimeManager: ObservableObject {
    @Published private(set) var state: RuntimeState
    @Published private(set) var localRuntime: RuntimeDescriptor?
    @Published private(set) var latestVersion: String?
    @Published private(set) var isChecking = false
    @Published private(set) var isInstalling = false
    @Published private(set) var statusMessage = ""

    let paths: HarnessPaths

    private static let customRuntimePathKey = "customDshPath"
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    init() throws {
        paths = try HarnessPaths()
        state = Self.loadState(from: paths.stateURL)
        localRuntime = nil
        try reconcileManagedState()
        refreshLocalRuntime(announce: false)
    }

    var activeVersion: String? { state.active }
    var pendingVersion: String? { state.pending }
    var previousVersion: String? { state.previous }
    var customLocalPath: String? { UserDefaults.standard.string(forKey: Self.customRuntimePathKey) }

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
        let root = paths.runtimeRoot(for: version)
        guard let descriptor = Self.managedDescriptor(at: root), descriptor.version == version else {
            return nil
        }
        return descriptor
    }

    func refreshLocalRuntime(announce: Bool = true) {
        localRuntime = Self.discoverLocalRuntime(
            paths: paths,
            customPath: UserDefaults.standard.string(forKey: Self.customRuntimePathKey)
        )
        guard announce else { return }
        if let localRuntime {
            statusMessage = "发现本机 Harness \(localRuntime.version)：\(localRuntime.executableURL.path)"
        } else {
            statusMessage = "没有在常见路径中发现本机 Harness"
        }
    }

    func setCustomLocalRuntime(_ url: URL) throws {
        guard let descriptor = Self.localDescriptor(at: url, paths: paths) else {
            throw RuntimeError.invalidLocalExecutable(url.path)
        }
        UserDefaults.standard.set(url.path, forKey: Self.customRuntimePathKey)
        localRuntime = descriptor
        statusMessage = "已选择本机 Harness \(descriptor.version)"
    }

    func clearCustomLocalRuntime() {
        UserDefaults.standard.removeObject(forKey: Self.customRuntimePathKey)
        refreshLocalRuntime()
    }

    func commitPending() throws {
        guard let pending = state.pending else { return }
        state.previous = state.active
        state.active = pending
        state.pending = nil
        try saveState()
        statusMessage = "已启用 App 管理的 Harness \(pending)"
    }

    func discardPending() throws {
        let failedVersion = state.pending
        state.pending = nil
        try saveState()
        if let failedVersion {
            statusMessage = "Harness \(failedVersion) 未启用"
        }
    }

    func promotePrevious() throws {
        guard let previous = state.previous else { return }
        let current = state.active
        state.active = previous
        state.previous = current
        state.pending = nil
        try saveState()
        statusMessage = "App 管理版本已切换为 \(previous)"
    }

    func checkForUpdates(currentVersion: String?, installAutomatically: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "正在查询 npm registry…"

        Task {
            do {
                let version = try await Self.fetchLatestVersion()
                latestVersion = version
                if version == currentVersion {
                    statusMessage = "当前 Harness 已是最新版 \(version)"
                } else if runtime(version: version) != nil {
                    statusMessage = "最新版 \(version) 已在 App 管理目录中"
                } else {
                    statusMessage = "发现 Harness \(version)"
                    if installAutomatically {
                        isChecking = false
                        install(version: version)
                        return
                    }
                }
            } catch {
                statusMessage = "查询更新失败：\(error.localizedDescription)"
            }
            isChecking = false
        }
    }

    func installLatest(onInstalled: ((Result<String, Error>) -> Void)? = nil) {
        if let latestVersion {
            install(version: latestVersion, onInstalled: onInstalled)
            return
        }
        guard !isChecking else {
            onInstalled?(.failure(RuntimeError.operationInProgress))
            return
        }

        isChecking = true
        statusMessage = "正在查询 npm registry…"
        Task {
            do {
                let version = try await Self.fetchLatestVersion()
                latestVersion = version
                isChecking = false
                install(version: version, onInstalled: onInstalled)
            } catch {
                isChecking = false
                statusMessage = "查询更新失败：\(error.localizedDescription)"
                onInstalled?(.failure(error))
            }
        }
    }

    func install(version: String, onInstalled: ((Result<String, Error>) -> Void)? = nil) {
        guard !isInstalling else {
            onInstalled?(.failure(RuntimeError.operationInProgress))
            return
        }
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
                        self.statusMessage = "Harness \(version) 已下载，等待启用"
                        onInstalled?(.success(version))
                    } catch {
                        self.statusMessage = "保存待启用版本失败：\(error.localizedDescription)"
                        onInstalled?(.failure(error))
                    }
                case .failure(let error):
                    self.statusMessage = "安装失败：\(error.localizedDescription)"
                    onInstalled?(.failure(error))
                }
            }
        }
    }

    private func reconcileManagedState() throws {
        var changed = false
        if let active = state.active, runtime(version: active) == nil {
            state.active = nil
            changed = true
        }
        if let pending = state.pending, runtime(version: pending) == nil {
            state.pending = nil
            changed = true
        }
        if let previous = state.previous, runtime(version: previous) == nil {
            state.previous = nil
            changed = true
        }
        if changed {
            try saveState()
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

    nonisolated private static func managedDescriptor(at root: URL) -> RuntimeDescriptor? {
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
            executableURL: entryURL,
            source: .managed
        )
    }

    nonisolated private static func discoverLocalRuntime(
        paths: HarnessPaths,
        customPath: String?
    ) -> RuntimeDescriptor? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        var candidates: [URL] = []
        if let customPath {
            candidates.append(URL(fileURLWithPath: customPath))
        }
        candidates.append(contentsOf: [
            URL(fileURLWithPath: "/opt/homebrew/bin/dsh"),
            URL(fileURLWithPath: "/usr/local/bin/dsh"),
            home.appendingPathComponent(".local/bin/dsh"),
            home.appendingPathComponent("Library/pnpm/dsh"),
        ])
        candidates.append(contentsOf: npxCacheCandidates(
            home: home,
            fileManager: fileManager
        ))
        let environmentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        candidates.append(contentsOf: environmentPath
            .split(separator: ":")
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("dsh") })

        var visited = Set<String>()
        for candidate in candidates where visited.insert(candidate.path).inserted {
            if let descriptor = localDescriptor(at: candidate, paths: paths) {
                return descriptor
            }
        }
        return nil
    }

    nonisolated private static func npxCacheCandidates(
        home: URL,
        fileManager: FileManager
    ) -> [URL] {
        let cacheRoot = home.appendingPathComponent(".npm/_npx", isDirectory: true)
        guard let entries = try? fileManager.contentsOfDirectory(
            at: cacheRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return entries
            .sorted { left, right in
                let leftDate = try? left.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let rightDate = try? right.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                return (leftDate ?? .distantPast) > (rightDate ?? .distantPast)
            }
            .map { $0.appendingPathComponent("node_modules/.bin/dsh") }
    }

    nonisolated private static func localDescriptor(
        at executableURL: URL,
        paths: HarnessPaths
    ) -> RuntimeDescriptor? {
        let fileManager = FileManager.default
        guard fileManager.isExecutableFile(atPath: executableURL.path) else { return nil }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["--version"]
        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? ""
        environment["PATH"] = [
            executableURL.deletingLastPathComponent().path,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            paths.bundledNodeBinDirectory.path,
            existingPath,
        ].filter { !$0.isEmpty }.joined(separator: ":")
        process.environment = environment
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let version = output
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
                .first(where: { $0.first?.isNumber == true }) ?? output
            guard !version.isEmpty else { return nil }
            return RuntimeDescriptor(
                version: version,
                executableURL: executableURL,
                source: .local
            )
        } catch {
            return nil
        }
    }

    nonisolated private static func fetchLatestVersion() async throws -> String {
        let url = URL(string: "https://registry.npmjs.org/@deepseek-ai%2Fdsh/latest")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LatestRelease.self, from: data).version
    }

    nonisolated private static func performInstall(
        version: String,
        paths: HarnessPaths
    ) -> Result<Void, Error> {
        do {
            let fileManager = FileManager.default
            guard fileManager.isExecutableFile(atPath: paths.bundledNodeURL.path) else {
                throw RuntimeError.missingEngine(paths.bundledNodeURL.path)
            }
            guard fileManager.fileExists(atPath: paths.bundledNpmCLIURL.path) else {
                throw RuntimeError.missingNpm(paths.bundledNpmCLIURL.path)
            }

            let destination = paths.runtimeRoot(for: version)
            if let installed = managedDescriptor(at: destination), installed.version == version {
                return .success(())
            }

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
            guard let installed = managedDescriptor(at: destination), installed.version == version else {
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
    case invalidLocalExecutable(String)
    case missingEngine(String)
    case missingNpm(String)
    case npmFailed(Int32, String)
    case missingInstalledRuntime(String)
    case operationInProgress

    var errorDescription: String? {
        switch self {
        case .invalidLocalExecutable(let path):
            return "无法运行所选 Harness：\(path)"
        case .missingEngine(let path):
            return "找不到内置 Node：\(path)"
        case .missingNpm(let path):
            return "找不到内置 npm：\(path)"
        case .npmFailed(let status, let log):
            return "npm 退出码 \(status)，日志：\(log)"
        case .missingInstalledRuntime(let version):
            return "npm 完成后未找到 Harness \(version)"
        case .operationInProgress:
            return "已有 Runtime 操作正在进行"
        }
    }
}
