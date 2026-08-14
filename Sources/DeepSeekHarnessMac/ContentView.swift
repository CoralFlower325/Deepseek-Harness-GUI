import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            mainContent

            if model.showsLogs {
                Divider()
                LogView(text: model.logs)
                    .frame(minHeight: 130, idealHeight: 190, maxHeight: 280)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
        .toolbar {
            ToolbarItem(placement: .principal) {
                AppVersionLabel()
            }

            ToolbarItemGroup(placement: .navigation) {
                Button(action: model.chooseWorkspace) {
                    Label(model.workspaceURL.lastPathComponent, systemImage: "folder")
                }
                .help(model.workspaceURL.path)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                StatusLabel(state: model.runState)

                Button {
                    model.showsRuntimeManager = true
                } label: {
                    Label("Runtime", systemImage: "shippingbox")
                }

                Button(action: model.restart) {
                    Label("重启 Harness", systemImage: "arrow.clockwise")
                }

                Button {
                    model.showsLogs.toggle()
                } label: {
                    Label("日志", systemImage: "terminal")
                }
            }
        }
        .sheet(isPresented: $model.showsRuntimeManager) {
            RuntimePanel(model: model)
        }
        .onAppear(perform: model.startIfNeeded)
    }

    @ViewBuilder
    private var mainContent: some View {
        switch model.runState {
        case .setupRequired(let message):
            VStack(spacing: 18) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("未找到 DeepSeek Harness")
                    .font(.title2.bold())
                Text("如果你已经安装过 Harness，请选择 dsh 可执行文件；如果尚未安装，可以让 App 从 npm 下载最新版。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 560)

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 620)
                }

                HStack(spacing: 12) {
                    Button("我已经安装，选择 dsh…", action: model.chooseLocalHarness)
                    Button("下载安装最新版", action: model.installHarnessForSetup)
                        .buttonStyle(.borderedProminent)
                    Button("重新检测", action: model.redetectLocalHarness)
                }

                Text("用户设置和 API Key 仍保存在官方目录 ~/.dsh，下载安装不会覆盖这些数据。")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .installing(let message):
            VStack(spacing: 14) {
                ProgressView()
                Text(message)
                    .font(.headline)
                Text("首次安装需要访问 npm registry。完成后 App 会自动启动 Harness。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .running(_, let url):
            HarnessWebView(url: url)

        case .starting(let version):
            VStack(spacing: 14) {
                ProgressView()
                Text("正在启动 DeepSeek Harness \(version)")
                    .font(.headline)
                Text(model.workspaceURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let message):
            ContentUnavailableView {
                Label("Harness 未运行", systemImage: "exclamationmark.circle")
            } description: {
                Text(message)
            } actions: {
                HStack {
                    Button("重新启动", action: model.startPreferredRuntime)
                    Button("选择 dsh…", action: model.chooseLocalHarness)
                    Button("下载安装最新版", action: model.installHarnessForSetup)
                    Button("查看日志") { model.showsLogs = true }
                }
            }

        case .stopped:
            ContentUnavailableView {
                Label("Harness 已停止", systemImage: "stop.circle")
            } actions: {
                Button("启动", action: model.startPreferredRuntime)
            }
        }
    }
}

private struct AppVersionLabel: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版"
    }

    var body: some View {
        HStack(spacing: 7) {
            Text("DeepSeek Harness GUI")
                .font(.headline)
            Text("v\(version)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .help("GUI 版本 v\(version)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DeepSeek Harness GUI 版本 \(version)")
    }
}

private struct StatusLabel: View {
    let state: HarnessRunState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(state.label)
                .font(.caption)
        }
        .padding(.horizontal, 8)
    }

    private var color: Color {
        switch state {
        case .running:
            return .green
        case .starting, .installing:
            return .orange
        case .failed:
            return .red
        case .setupRequired, .stopped:
            return .secondary
        }
    }
}

private struct LogView: View {
    let text: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text.isEmpty ? "等待 Harness 输出…" : text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .id("bottom")
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: text) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
}

private struct RuntimePanel: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var manager: RuntimeManager

    init(model: AppModel) {
        self.model = model
        manager = model.runtimeManager
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Harness Runtime")
                        .font(.title2.bold())
                    Text(manager.statusMessage.isEmpty ? "选择本机 Harness，或管理独立于 Mac App 的版本" : manager.statusMessage)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { model.showsRuntimeManager = false }
                    .keyboardShortcut(.defaultAction)
            }

            Picker(
                "启动来源",
                selection: Binding(
                    get: { model.runtimePreference },
                    set: { model.setRuntimePreference($0) }
                )
            ) {
                ForEach(RuntimePreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    Text("正在使用")
                    Text(model.currentRuntime?.source.title ?? "未运行")
                }
                GridRow {
                    Text("当前版本")
                    Text(model.currentRuntime?.version ?? "无")
                        .font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("当前路径")
                    Text(model.currentRuntime?.executableURL.path ?? "无")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                GridRow {
                    Text("发现本机版本")
                    Text(manager.localRuntime.map { "\($0.version) · \($0.executableURL.path)" } ?? "无")
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
                GridRow {
                    Text("App 管理版本")
                    Text(manager.activeVersion ?? "无")
                        .font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("待启用")
                    Text(manager.pendingVersion ?? "无")
                        .font(.system(.body, design: .monospaced))
                }
                GridRow {
                    Text("上一版本")
                    Text(manager.previousVersion ?? "无")
                        .font(.system(.body, design: .monospaced))
                }
            }

            HStack {
                Button("重新检测本机 Harness", action: model.redetectLocalHarness)
                Button("选择 dsh…", action: model.chooseLocalHarness)

                if manager.localRuntime != nil, model.currentRuntime?.source != .local {
                    Button("使用本机版本") {
                        model.setRuntimePreference(.automatic)
                    }
                }
                if manager.activeRuntime() != nil, model.currentRuntime?.source != .managed {
                    Button("使用 App 管理版本") {
                        model.setRuntimePreference(.managed)
                    }
                }
            }

            Divider()

            Picker("更新策略", selection: $model.updatePolicy) {
                ForEach(UpdatePolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }

            HStack {
                Button("检查更新") {
                    manager.checkForUpdates(currentVersion: model.currentRuntime?.version)
                }
                .disabled(manager.isChecking || manager.isInstalling)

                if let latest = manager.latestVersion, latest != model.currentRuntime?.version {
                    Button(model.currentRuntime?.source == .local ? "下载为 App 管理版本 \(latest)" : "下载 \(latest)") {
                        manager.installLatest()
                    }
                    .disabled(manager.isInstalling)
                }

                if manager.pendingVersion != nil {
                    Button("立即重启并启用") {
                        model.activatePending()
                        model.showsRuntimeManager = false
                    }
                    .buttonStyle(.borderedProminent)
                }

                if manager.previousVersion != nil {
                    Button("尝试上一版本") {
                        model.tryPreviousRuntime()
                        model.showsRuntimeManager = false
                    }
                }
            }

            if manager.isChecking || manager.isInstalling {
                ProgressView()
                    .controlSize(.small)
            }

            Divider()
            Text("Runtime：\(manager.paths.runtimesRoot.path)")
            Text("用户数据：\(manager.paths.dshHome.path)")
            Text("更新日志：\(manager.paths.updateLogURL.path)")
            Text("本机安装由 Homebrew/npm 或用户自行更新；GUI 不会覆盖它。下载的 App 管理版本仍支持 pending 启用和 previous 回退。")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 780)
    }
}
