import Foundation

/// 服务器档案：保存 NAS 连接配置；密码单独存 Keychain。
struct ServerProfile: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String          // 用户备注名，如 "家里的 DS"
    var scheme: Scheme        // http / https
    var host: String          // IP / DDNS / QuickConnect ID
    var port: Int             // 默认 5000 / 5001
    var username: String
    var ignoreInvalidCertificate: Bool
    var lastConnectedAt: Date?

    enum Scheme: String, Codable, CaseIterable, Identifiable {
        case http, https
        var id: String { rawValue }
    }

    /// 拼装 baseURL。
    var baseURL: URL? {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = host
        components.port = port
        return components.url
    }

    /// 用于 UI 上展示的连接串。
    var displayURL: String {
        "\(scheme.rawValue)://\(host):\(port)"
    }

    /// 默认构造器：未命名时使用主机作为标题。
    init(
        id: UUID = UUID(),
        name: String = "",
        scheme: Scheme = .http,
        host: String,
        port: Int = 5000,
        username: String,
        ignoreInvalidCertificate: Bool = false,
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name.isEmpty ? host : name
        self.scheme = scheme
        self.host = host
        self.port = port
        self.username = username
        self.ignoreInvalidCertificate = ignoreInvalidCertificate
        self.lastConnectedAt = lastConnectedAt
    }
}
