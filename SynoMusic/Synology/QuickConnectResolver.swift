import Foundation

/// 群晖 QuickConnect ID 解析器：把 `myds` 这样的短串解析为真实可达的 host:port。
///
/// 通过群晖 global 端点 `global.quickconnect.to/Serv.php` 的 `get_server_info`
/// 命令拿到 server 信息：依次尝试外网 IP、内网接口 IP、FQDN，端口默认 5001
/// （HTTPS），从 `service.ext_port_https` 覆盖。该 API 协议未公开，文档来自社区
/// 逆向；字段命名可能随 DSM 版本演变，我们做防御性解析。
final class QuickConnectResolver: @unchecked Sendable {

    struct Resolved {
        let host: String
        let port: Int
        let scheme: ServerProfile.Scheme
    }

    /// 是否看起来是 QuickConnect ID：纯字母数字/下划线/连字符，且不含点（域名）或冒号。
    /// 这是一个启发判断，不严谨；用户也可以显式打开「按 QuickConnect 解析」开关。
    static func looksLikeID(_ host: String) -> Bool {
        let trimmed = host.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains(".") || trimmed.contains(":") { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    func resolve(_ id: String) async throws -> Resolved {
        let url = URL(string: "https://global.quickconnect.to/Serv.php")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 12

        // serverID 命名在不同 DSM 版本里有时是 serverID 有时是 server_id，
        // 这里两个都塞进去，群晖端会忽略不识别的键。
        let body: [String: Any] = [
            "version": 1,
            "command": "get_server_info",
            "stop_when_error": false,
            "stop_when_success": false,
            "id": "dsm_portal_https",
            "serverID": id,
            "server_id": id,
            "is_gofile": false
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "QuickConnect", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "QuickConnect 服务无响应"])
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "QuickConnect", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "QuickConnect 返回无法解析"])
        }
        if let code = obj["errno"] as? Int, code != 0 {
            throw NSError(domain: "QuickConnect", code: code,
                          userInfo: [NSLocalizedDescriptionKey: "QuickConnect 错误码 \(code)：ID 不存在或服务暂不可达"])
        }

        let server = (obj["server"] as? [String: Any]) ?? [:]
        let service = (server["service"] as? [String: Any]) ?? [:]

        var port = service["ext_port_https"] as? Int
            ?? service["ext_port"] as? Int
            ?? service["port"] as? Int
            ?? 5001
        let scheme: ServerProfile.Scheme = (service["https_port"] as? Int).map { _ in .https } ?? .https

        // 优先级：external.ipv6 → external.ip → fqdn → interface[i].ip
        let external = (server["external"] as? [String: Any]) ?? [:]
        var candidates: [String] = []
        if let v6 = external["ipv6"] as? String, !v6.isEmpty { candidates.append(v6) }
        if let v4 = external["ip"] as? String, !v4.isEmpty { candidates.append(v4) }
        if let fqdn = server["fqdn"] as? String, !fqdn.isEmpty, fqdn != "NULL" { candidates.append(fqdn) }
        if let ddns = server["ddns"] as? String, !ddns.isEmpty, ddns != "NULL" { candidates.append(ddns) }
        if let interfaces = server["interface"] as? [[String: Any]] {
            for iface in interfaces {
                if let ip = iface["ip"] as? String, !ip.isEmpty { candidates.append(ip) }
                if let v6 = iface["ipv6"] as? [[String: Any]] {
                    for entry in v6 {
                        if let addr = entry["address"] as? String, !addr.isEmpty { candidates.append(addr) }
                    }
                }
            }
        }
        if port == 0 { port = 5001 }
        guard let host = candidates.first else {
            throw NSError(domain: "QuickConnect", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "QuickConnect 解析未返回可达地址"])
        }
        return Resolved(host: host, port: port, scheme: scheme)
    }
}
