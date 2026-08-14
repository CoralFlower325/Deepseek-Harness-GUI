import SwiftUI

@main
struct DeepSeekHarnessMacApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("DeepSeek Harness") {
            ContentView(model: model)
        }
        .defaultSize(width: 1180, height: 780)
        .commands {
            CommandGroup(after: .newItem) {
                Button("选择工作区…", action: model.chooseWorkspace)
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandMenu("Harness") {
                Button("重新启动", action: model.restart)
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Button("停止", action: model.stop)
                Divider()
                Button("Runtime 管理…") {
                    model.showsRuntimeManager = true
                }
            }
        }
    }
}
