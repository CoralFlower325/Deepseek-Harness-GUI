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
                    Button("重新启动", action: model.startActiveRuntime)
                    Button("查看日志") { model.showsLogs = true }
                }
            }
        case .stopped:
            ContentUnavailableView {
                Label("Harness 已停止", systemImage: "stop.circle")
            } actions: {
                Button("启动", action: model.startActiveRuntime)
            }
        }
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
        case .starting:
            return .orange
        case .failed:
            return .red
        case .stopped:
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
                    Text(manager.statusMessage.isEmpty ? "管理独立于 Mac App 的 Harness 版本" : manager.statusMessage)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { model.showsRuntimeManager = false }
                    .keyboardShortcut(.defaultAction)
            }

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    Text("当前版本")
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

            Picker("更新策略", selection: $model.updatePolicy) {
                ForEach(UpdatePolicy.allCases) { policy in
                    Text(policy.title).tag(policy)
                }
            }

            HStack {
                Button("检查更新") {
                    manager.checkForUpdates()
                }
                .disabled(manager.isChecking || manager.isInstalling)

                if let latest = manager.latestVersion, latest != manager.activeVersion {
                    Button("下载 \(latest)") {
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
            Text("上一版本按钮只切换可执行 runtime，不承诺降级读取已由新版写入的数据。")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 660)
    }
}
