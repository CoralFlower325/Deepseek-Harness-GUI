import Foundation

struct RuntimeState: Codable, Equatable {
    var active: String?
    var pending: String?
    var previous: String?

    static let empty = RuntimeState(active: nil, pending: nil, previous: nil)
}

struct RuntimeDescriptor: Equatable {
    let version: String
    let rootURL: URL
    let entryURL: URL
    let isBundledSeed: Bool
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
    case stopped
    case starting(String)
    case running(version: String, url: URL)
    case failed(String)

    var label: String {
        switch self {
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
