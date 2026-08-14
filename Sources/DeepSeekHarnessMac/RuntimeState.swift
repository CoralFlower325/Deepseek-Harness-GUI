import Foundation

struct RuntimeState: Codable, Equatable {
    var active: String?
    var pending: String?
    var previous: String?

    static let empty = RuntimeState(active: nil, pending: nil, previous: nil)
}

enum RuntimeSource: String, Equatable {
    case local
    case managed

    var title: String {
        switch self {
        case .local:
            return "本机安装"
        case .managed:
            return "App 管理"
        }
    }
}

struct RuntimeDescriptor: Equatable {
    let version: String
    let executableURL: URL
    let source: RuntimeSource
}

enum RuntimePreference: String, CaseIterable, Identifiable {
    case automatic
    case managed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "自动选择（优先本机安装）"
        case .managed:
            return "仅使用 App 管理版本"
        }
    }
}

enum UpdatePolicy: String, CaseIterable, Identifiable {
    case ask
    case automatic
    case pinned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ask:
            return "发现新版后询问"
        case .automatic:
            return "自动下载，下次启动启用"
        case .pinned:
            return "固定当前版本"
        }
    }
}

enum HarnessRunState: Equatable {
    case setupRequired(String?)
    case installing(String)
    case stopped
    case starting(String)
    case running(version: String, url: URL)
    case failed(String)

    var label: String {
        switch self {
        case .setupRequired:
            return "需要设置"
        case .installing:
            return "正在安装"
        case .stopped:
            return "已停止"
        case .starting(let version):
            return "正在启动 \(version)"
        case .running(let version, _):
            return "运行中 · \(version)"
        case .failed:
            return "启动失败"
        }
    }
}
