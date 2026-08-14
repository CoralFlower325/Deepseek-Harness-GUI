import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var runState: HarnessRunState = .stopped
    @Published private(set) var currentRuntime: RuntimeDescriptor?
    @Published var logs = ""
    @Published var showsLogs = false
    @Published var showsRuntimeManager = false
    @Published private(set) var workspaceURL: URL
    @Published var runtimePreference: RuntimePreference {
        didSet { UserDefaults.standard.set(runtimePreference.rawValue, forKey: Self.runtimePreferenceKey) }
    }
    @Published var updatePolicy: UpdatePolicy {
        didSet { UserDefaults.standard.set(updatePolicy.rawValue, forKey: Self.updatePolicyKey) }
    }

    let runtimeManager: RuntimeManager
    private let processController = HarnessProcessController()
    private var hasStarted = false

    private static let workspaceKey = "workspacePath"
    private static let runtimePreferenceKey = "runtimePreference"
    private static let updatePolicyKey = "updatePolicy"

    init() {
        let storedWorkspace = UserDefaults.standard.string(forKey: Self.workspaceKey)
        let defaultWorkspace = FileManager.default.homeDirectoryForCurrentUser
        workspaceURL = storedWorkspace.map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? defaultWorkspace

        let storedPreference = UserDefaults.standard.string(forKey: Self.runtimePreferenceKey)
        runtimePreference = RuntimePreference(rawValue: storedPreference ?? "") ?? .automatic

        let storedPolicy = UserDefaults.standard.string(forKey: Self.updatePolicyKey)
        updatePolicy = UpdatePolicy(rawValue: storedPolicy ?? "") ?? .ask

        do {
            runtimeManager = try RuntimeManager()
        } catch {
            fatalError("无法初始化 Runtime 目录：\(error.localizedDescription)")
        }
    }

    var webURL: URL? {
        guard case .running(_, let url) = runState else { return nil }
        return url
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        startPreferredRuntime()
    }

    func startPreferredRuntime() {
        currentRuntime = nil
        runtimeManager.refreshLocalRuntime(announce: false)

        if runtimePreference == .automatic, let local = runtimeManager.localRuntime {
            launch(runtime: local, commitsPending: false, allowsManagedFallback: true)
            return
        }
        startManagedRuntimeOrSetup()
    }

    func restart() {
        Task {
            await processController.stop()
            startPreferredRuntime()
        }
    }

    func stop() {
        Task {
            await processController.stop()
            currentRuntime = nil
            runState = .stopped
        }
    }

    func setRuntimePreference(_ preference: RuntimePreference) {
        runtimePreference = preference
        restart()
    }

    func redetectLocalHarness() {
        runtimeManager.refreshLocalRuntime()
        guard runtimeManager.localRuntime != nil else {
            if currentRuntime == nil {
                runState = .setupRequired("仍未在常见路径中发现 Harness。你可以手动选择 dsh，或下载安装最新版。")
            }
            return
        }
        runtimePreference = .automatic
        restart()
    }

    func chooseLocalHarness() {
        let panel = NSOpenPanel()
        panel.title = "选择 DeepSeek Harness 可执行文件"
        panel.message = "请选择 dsh 可执行文件，而不是工作区目录。"
        panel.prompt = "使用此 dsh"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        if let customPath = runtimeManager.customLocalPath {
            panel.directoryURL = URL(fileURLWithPath: customPath).deletingLastPathComponent()
        }

        guard panel.runModal() == .OK, let selected = panel.url else { return }
        do {
            try runtimeManager.setCustomLocalRuntime(selected)
            runtimePreference = .automatic
            Task {
                await processController.stop()
                if let local = runtimeManager.localRuntime {
                    launch(runtime: local, commitsPending: false, allowsManagedFallback: true)
                }
            }
        } catch {
            runState = .setupRequired(error.localizedDescription)
        }
    }

    func installHarnessForSetup() {
        runState = .installing("正在从 npm 获取并安装最新 Harness…")
        runtimeManager.installLatest { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.runtimePreference = .managed
                self.activatePending()
            case .failure(let error):
                self.runState = .setupRequired("下载安装失败：\(error.localizedDescription)")
            }
        }
    }

    func activatePending() {
        guard let pending = runtimeManager.pendingRuntime() else {
            runState = .setupRequired("下载完成后没有找到可启用的 Harness runtime。")
            return
        }
        runtimePreference = .managed
        Task {
            await processController.stop()
            launch(runtime: pending, commitsPending: true)
        }
    }

    func tryPreviousRuntime() {
        guard let previous = runtimeManager.previousRuntime() else { return }
        runtimePreference = .managed
        Task {
            await processController.stop()
            launch(runtime: previous, commitsPending: false, promotePreviousOnReady: true)
        }
    }

    func chooseWorkspace() {
        let panel = NSOpenPanel()
        panel.title = "选择 DeepSeek Harness 工作区"
        panel.prompt = "选择"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = workspaceURL

        guard panel.runModal() == .OK, let selected = panel.url else { return }
        workspaceURL = selected
        UserDefaults.standard.set(selected.path, forKey: Self.workspaceKey)
        restart()
    }

    private func startManagedRuntimeOrSetup(reason: String? = nil) {
        if let pending = runtimeManager.pendingRuntime(),
           runtimeManager.activeRuntime() == nil || updatePolicy == .automatic {
            launch(runtime: pending, commitsPending: true)
            return
        }
        if let active = runtimeManager.activeRuntime() {
            launch(runtime: active, commitsPending: false)
            return
        }
        currentRuntime = nil
        runState = .setupRequired(reason)
    }

    private func launch(
        runtime: RuntimeDescriptor,
        commitsPending: Bool,
        promotePreviousOnReady: Bool = false,
        allowsManagedFallback: Bool = false
    ) {
        currentRuntime = nil
        runState = .starting(runtime.version)
        appendLog("启动 \(runtime.source.title) Harness \(runtime.version)：\(runtime.executableURL.path)")

        do {
            try processController.start(
                runtime: runtime,
                nodeURL: runtimeManager.paths.bundledNodeURL,
                nodeBinDirectory: runtimeManager.paths.bundledNodeBinDirectory,
                dshHome: runtimeManager.paths.dshHome,
                workspace: workspaceURL,
                onLog: { [weak self] line in
                    self?.appendLog(line)
                },
                onReady: { [weak self] url in
                    guard let self else { return }
                    do {
                        if commitsPending {
                            try self.runtimeManager.commitPending()
                        } else if promotePreviousOnReady {
                            try self.runtimeManager.promotePrevious()
                        }
                        self.currentRuntime = runtime
                        self.runState = .running(version: runtime.version, url: url)
                        self.applyUpdatePolicyAfterStartup(runtime: runtime)
                    } catch {
                        self.runState = .failed("切换 runtime 状态失败：\(error.localizedDescription)")
                    }
                },
                onExit: { [weak self] status, intentional, reachedReady in
                    guard let self else { return }
                    if intentional { return }
                    self.currentRuntime = nil

                    if allowsManagedFallback && !reachedReady {
                        self.appendLog("本机 Harness 启动失败，尝试 App 管理版本")
                        self.startManagedRuntimeOrSetup(
                            reason: "本机 Harness 启动失败，且没有可用的 App 管理版本。请选择 dsh 或下载安装。"
                        )
                    } else if commitsPending && !reachedReady {
                        do {
                            try self.runtimeManager.discardPending()
                            self.appendLog("新版启动失败，尝试原 App 管理版本")
                            self.startManagedRuntimeOrSetup(
                                reason: "下载的 Harness 启动失败。你可以重试安装或选择本机 dsh。"
                            )
                        } catch {
                            self.runState = .failed("新版退出码 \(status)，且无法恢复版本状态：\(error.localizedDescription)")
                        }
                    } else {
                        self.runState = .failed("Harness 已退出，退出码 \(status)")
                    }
                }
            )
        } catch {
            if allowsManagedFallback {
                appendLog("无法启动本机 Harness：\(error.localizedDescription)")
                startManagedRuntimeOrSetup(
                    reason: "无法启动本机 Harness，且没有可用的 App 管理版本。请选择 dsh 或下载安装。"
                )
            } else {
                runState = .failed("无法启动 Harness：\(error.localizedDescription)")
            }
        }
    }

    private func applyUpdatePolicyAfterStartup(runtime: RuntimeDescriptor) {
        switch updatePolicy {
        case .ask:
            runtimeManager.checkForUpdates(currentVersion: runtime.version)
        case .automatic:
            runtimeManager.checkForUpdates(
                currentVersion: runtime.version,
                installAutomatically: runtime.source == .managed
            )
        case .pinned:
            break
        }
    }

    private func appendLog(_ line: String) {
        guard !line.isEmpty else { return }
        if logs.isEmpty {
            logs = line
        } else {
            logs.append("\n" + line)
        }
    }
}
