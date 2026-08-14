import AppKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var runState: HarnessRunState = .stopped
    @Published var logs = ""
    @Published var showsLogs = false
    @Published var showsRuntimeManager = false
    @Published private(set) var workspaceURL: URL
    @Published var updatePolicy: UpdatePolicy {
        didSet { UserDefaults.standard.set(updatePolicy.rawValue, forKey: Self.updatePolicyKey) }
    }

    let runtimeManager: RuntimeManager
    private let processController = HarnessProcessController()
    private var hasStarted = false

    private static let workspaceKey = "workspacePath"
    private static let updatePolicyKey = "updatePolicy"

    init() {
        let storedWorkspace = UserDefaults.standard.string(forKey: Self.workspaceKey)
        let defaultWorkspace = FileManager.default.homeDirectoryForCurrentUser
        workspaceURL = storedWorkspace.map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? defaultWorkspace

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

        if updatePolicy == .automatic, let pending = runtimeManager.pendingRuntime() {
            launch(runtime: pending, commitsPending: true)
        } else {
            startActiveRuntime()
        }
    }

    func startActiveRuntime() {
        guard let runtime = runtimeManager.activeRuntime() else {
            runState = .failed("找不到可启动的 Harness runtime。请重新制作包含 seed runtime 的 App。")
            return
        }
        launch(runtime: runtime, commitsPending: false)
    }

    func restart() {
        Task {
            await processController.stop()
            startActiveRuntime()
        }
    }

    func stop() {
        Task {
            await processController.stop()
            runState = .stopped
        }
    }

    func activatePending() {
        guard let pending = runtimeManager.pendingRuntime() else { return }
        Task {
            await processController.stop()
            launch(runtime: pending, commitsPending: true)
        }
    }

    func tryPreviousRuntime() {
        guard let previous = runtimeManager.previousRuntime() else { return }
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

    private func launch(
        runtime: RuntimeDescriptor,
        commitsPending: Bool,
        promotePreviousOnReady: Bool = false
    ) {
        runState = .starting(runtime.version)
        appendLog("启动 Harness \(runtime.version)")

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
                        self.runState = .running(version: runtime.version, url: url)
                        self.applyUpdatePolicyAfterStartup()
                    } catch {
                        self.runState = .failed("切换 runtime 状态失败：\(error.localizedDescription)")
                    }
                },
                onExit: { [weak self] status, intentional, reachedReady in
                    guard let self else { return }
                    if intentional { return }

                    if commitsPending && !reachedReady {
                        do {
                            try self.runtimeManager.discardPending()
                            self.appendLog("新版启动失败，重新启动原 active runtime")
                            self.startActiveRuntime()
                        } catch {
                            self.runState = .failed("新版退出码 \(status)，且无法恢复 active 状态：\(error.localizedDescription)")
                        }
                    } else {
                        self.runState = .failed("Harness 已退出，退出码 \(status)")
                    }
                }
            )
        } catch {
            runState = .failed("无法启动 Harness：\(error.localizedDescription)")
        }
    }

    private func applyUpdatePolicyAfterStartup() {
        switch updatePolicy {
        case .ask:
            runtimeManager.checkForUpdates()
        case .automatic:
            runtimeManager.checkForUpdates(installAutomatically: true)
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
