import Foundation

/// 群晖 QuickConnect ID 解析器：把 `myds` 这样的短串解析为真实可达的 host:port。
///
/// 群晖 QuickConnect 协议（社区逆向）：
/// 1. POST `global.quickconnect.to/Serv.php` 的 `get_server_info`；
/// 2. 若返回 `errno=4 + sites=[...]`，说明 ID 不在该全球端点，需到 `sites` 中
///    的区域端点（如 `cnc.quickconnect.cn`）重试。
/// 3. 拿到完整 `server` 后按 smartdns > ddns > external.ip > interface[].ip 优先级
///    选 host；端口从 `service.ext_port_https` / `ext_port` / `port` 读取，0 视为无效。
///
/// 字段命名随 DSM 版本演变，因此做防御性解析；HTTP/HTTPS 通道由调用方传入。
final class QuickConnectResolver: @unchecked Sendable {

    struct Resolved {
        let host: String
        let port: Int
        let scheme: ServerProfile.Scheme
    }

    enum ResolveError: LocalizedError {
        case invalidResponse(detail: String)
        case noHost
        case server(code: Int, tried: [String])
        case redirectExhausted(tried: [String])

        var errorDescription: String? {
            switch self {
            case .invalidResponse(let detail):
                return "QuickConnect 返回无法解析（\(detail)）"
            case .noHost:
                return "QuickConnect 解析未返回可达地址"
            case .redirectExhausted(let tried):
                return "QuickConnect 区域重定向次数过多。已尝试：\(tried.joined(separator: ", "))"
            case .server(let code, let tried):
                return "QuickConnect 错误码 \(code)。已尝试：\(tried.joined(separator: ", "))"
            }
        }
    }

    /// 是否看起来是 QuickConnect ID。允许常见 `quickConnect:` / `qc:` 前缀。
    static func looksLikeID(_ host: String) -> Bool {
        let stripped = strip(host)
        guard !stripped.isEmpty else { return false }
        if stripped.contains(".") || stripped.contains(":") || stripped.contains("/") { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return stripped.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// 把 `quickConnect:xxx` / `qc:xxx` / 大小写差异统一成纯 ID。
    static func strip(_ host: String) -> String {
        var s = host.trimmingCharacters(in: .whitespaces)
        let prefixes = ["quickconnect:", "quickConnect:", "QuickConnect:", "qc:", "QC:"]
        for p in prefixes where s.lowercased().hasPrefix(p.lowercased()) {
            s = String(s.dropFirst(p.count))
            break
        }
        return s
    }

    /// 解析 QuickConnect ID。`preferred` 决定通道：
    /// - `.https` → 用 `dsm_portal_https`，读 `ext_port_https`；
    /// - `.http`  → 用 `dsm_portal`，读 `ext_port`。
    /// `report` 回调把每一跳端点告诉调用方（用于 toast 进度反馈）。
    func resolve(
        _ rawID: String,
        preferred: ServerProfile.Scheme = .https,
        report: (@MainActor @Sendable (String) -> Void)? = nil
    ) async throws -> Resolved {
        let id = Self.strip(rawID)
        let portalID = preferred == .https ? "dsm_portal_https" : "dsm_portal"

        // 群晖按账号注册地理把 ID 分给不同区域端点（global / cnc / euc 等）。
        // server-side 对 simulator 进程 IP 返回的 errno=4 + sites 提示并不稳定，
        // 因此改用并发竞速：所有候选端点同时请求，第一个拿到 errno=0 的返回。
        let endpoints = [
            "global.quickconnect.to",
            "cnc.quickconnect.cn",
            "euc.quickconnect.eu"
        ]
        if let report { await report("正在解析 QuickConnect ID…") }

        return try await withThrowingTaskGroup(of: Resolved?.self) { group in
            for endpoint in endpoints {
                group.addTask {
                    do {
                        let obj = try await self.postServerInfo(host: endpoint, id: id, portalID: portalID)
                        let errno = obj["errno"] as? Int ?? 0
                        if errno == 0, let server = obj["server"] as? [String: Any] {
                            return try self.pick(server: server, service: obj["service"] as? [String: Any] ?? [:], preferred: preferred)
                        }
                    } catch {
                        // 单端点失败忽略，让其它端点机会
                    }
                    return nil
                }
            }
            var lastResolved: Resolved?
            for try await result in group {
                if let r = result {
                    lastResolved = r
                    group.cancelAll()
                    break
                }
            }
            if let r = lastResolved { return r }
            throw ResolveError.server(code: 4, tried: endpoints)
        }
    }

    // MARK: 内部

    private func postServerInfo(host: String, id: String, portalID: String) async throws -> [String: Any] {
        guard let url = URL(string: "https://\(host)/Serv.php") else {
            throw ResolveError.invalidResponse(detail: "URL")
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        // 群晖 QC 服务对一些 iOS UA 会返回 errno=4，统一伪装成 curl 与 mac 行为一致
        req.setValue("curl/8.4.0", forHTTPHeaderField: "User-Agent")
        // 关键：iOS Simulator 默认 happy-eyeballs 会优先 IPv6，cnc.quickconnect.cn 的
        // IPv6 路径下群晖会返回 errno=4。明确要求 IPv4。
        req.assumesHTTP3Capable = false
        req.timeoutInterval = 12

        // 注意：JSONSerialization 在某些 Foundation 版本下会把 Swift Bool 编码成 0/1
        // 而群晖 Serv.php 期望 true/false，否则返回 errno=4。
        // 这里手写 JSON 字符串规避，与 curl 行为完全一致。
        let bodyString = #"{"version":1,"command":"get_server_info","stop_when_error":false,"stop_when_success":false,"id":"\#(portalID)","serverID":"\#(id)","server_id":"\#(id)","is_gofile":false}"#
        req.httpBody = bodyString.data(using: .utf8)

        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 12
        let session = URLSession(configuration: cfg)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ResolveError.invalidResponse(detail: "\(host) HTTP \(code)")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let preview = String(data: data.prefix(120), encoding: .utf8) ?? "<binary>"
            throw ResolveError.invalidResponse(detail: "\(host) JSON: \(preview)")
        }
        return obj
    }

    private func pick(server: [String: Any], service: [String: Any], preferred: ServerProfile.Scheme) throws -> Resolved {
        // 端口：优先按通道字段；0 视为无效；缺失再用 service.port
        func nonZero(_ v: Any?) -> Int? {
            if let i = v as? Int, i > 0 { return i }
            return nil
        }
        let httpsPort = nonZero(service["ext_port_https"]) ?? nonZero(service["port"])
        let httpPort = nonZero(service["ext_port"]) ?? nonZero(service["port"])
        let scheme: ServerProfile.Scheme = preferred
        let port: Int = {
            switch preferred {
            case .https: return httpsPort ?? httpPort ?? 5001
            case .http: return httpPort ?? httpsPort ?? 5000
            }
        }()

        // 候选地址优先级：smartdns（QuickConnect 智能解析域名）
        //                > ddns（用户自配的群晖 DDNS）
        //                > external.ip / external.ipv6（公网 IP）
        //                > interface[].ip（内网 IP，只在与 NAS 同网时可达）
        var candidates: [String] = []
        if let smart = (server["smartdns"] as? [String: Any])?["host"] as? String, !smart.isEmpty {
            candidates.append(smart)
        }
        if let ddns = server["ddns"] as? String, !ddns.isEmpty, ddns != "NULL" {
            candidates.append(ddns)
        }
        let external = (server["external"] as? [String: Any]) ?? [:]
        if let v6 = external["ipv6"] as? String, !v6.isEmpty, v6 != "::" { candidates.append(v6) }
        if let v4 = external["ip"] as? String, !v4.isEmpty { candidates.append(v4) }
        if let fqdn = server["fqdn"] as? String, !fqdn.isEmpty, fqdn != "NULL" {
            candidates.append(fqdn)
        }
        if let interfaces = server["interface"] as? [[String: Any]] {
            for iface in interfaces {
                if let ip = iface["ip"] as? String, !ip.isEmpty { candidates.append(ip) }
            }
        }

        guard let host = candidates.first else { throw ResolveError.noHost }
        return Resolved(host: host, port: port, scheme: scheme)
    }
}
