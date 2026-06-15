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
    /// 是否通过 QuickConnect ID 创建；开启后编辑器只展示 ID 字段，host/port/scheme 由解析器填。
    var isQuickConnect: Bool
    /// 用户填写的 QuickConnect ID（保留显示）。
    var quickConnectID: String

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
        if isQuickConnect, !quickConnectID.isEmpty {
            return "QC: \(quickConnectID)"
        }
        return "\(scheme.rawValue)://\(host):\(port)"
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        scheme: Scheme = .http,
        host: String,
        port: Int = 5000,
        username: String,
        ignoreInvalidCertificate: Bool = false,
        lastConnectedAt: Date? = nil,
        isQuickConnect: Bool = false,
        quickConnectID: String = ""
    ) {
        self.id = id
        self.name = name.isEmpty ? host : name
        self.scheme = scheme
        self.host = host
        self.port = port
        self.username = username
        self.ignoreInvalidCertificate = ignoreInvalidCertificate
        self.lastConnectedAt = lastConnectedAt
        self.isQuickConnect = isQuickConnect
        self.quickConnectID = quickConnectID
    }

    // 旧版本档案兼容解码（没有 isQuickConnect / quickConnectID 字段）。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.scheme = try c.decode(Scheme.self, forKey: .scheme)
        self.host = try c.decode(String.self, forKey: .host)
        self.port = try c.decode(Int.self, forKey: .port)
        self.username = try c.decode(String.self, forKey: .username)
        self.ignoreInvalidCertificate = try c.decode(Bool.self, forKey: .ignoreInvalidCertificate)
        self.lastConnectedAt = try c.decodeIfPresent(Date.self, forKey: .lastConnectedAt)
        self.isQuickConnect = try c.decodeIfPresent(Bool.self, forKey: .isQuickConnect) ?? false
        self.quickConnectID = try c.decodeIfPresent(String.self, forKey: .quickConnectID) ?? ""
    }
}
