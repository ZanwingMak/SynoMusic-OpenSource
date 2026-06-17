import Foundation

/// 群晖 QuickConnect ID 解析器：把 `myds` 这样的短串解析为真实可达的 host:port。
///
/// 群晖 QuickConnect 协议（社区逆向）：
/// 1. POST `global.quickconnect.to/Serv.php` 的 `get_server_info`；
/// 2. 若返回 `errno=4 + sites=[...]`，说明 ID 不在该全球端点，需到 `sites` 中
///    的区域端点（如 `cnc.quickconnect.cn`）重试。
/// 3. 拿到完整 `server` 后生成多个候选地址；登录层会逐个尝试，避免单一候选不可达。
///
/// 字段命名随 DSM 版本演变，因此做防御性解析；HTTP/HTTPS 通道由调用方传入。
final class QuickConnectResolver: @unchecked Sendable {

    struct Candidate: Hashable {
        let host: String
        let port: Int
        let scheme: ServerProfile.Scheme
    }

    struct Resolved {
        let candidates: [Candidate]

        var host: String { candidates[0].host }
        var port: Int { candidates[0].port }
        var scheme: ServerProfile.Scheme { candidates[0].scheme }
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

        var pending = ["global.quickconnect.to", "cnc.quickconnect.cn", "euc.quickconnect.eu"]
        var tried: [String] = []
        if let report { await report("正在解析 QuickConnect ID…") }

        while !pending.isEmpty {
            let endpoint = pending.removeFirst()
            guard !tried.contains(endpoint) else { continue }
            tried.append(endpoint)
            if let report { await report("正在连接...") }

            let objects = try await postServerInfo(host: endpoint, id: id, preferred: preferred)
            for obj in objects {
                let errno = obj["errno"] as? Int ?? 0
                if errno == 0, let server = obj["server"] as? [String: Any] {
                    let service = pickService(from: obj, server: server, portalID: portalID)
                    return try pick(response: obj, server: server, service: service, preferred: preferred)
                }
                if errno == 4, let sites = obj["sites"] as? [String] {
                    for site in sites where !tried.contains(site) && !pending.contains(site) {
                        pending.insert(site, at: 0)
                    }
                }
            }
        }
        throw ResolveError.server(code: 4, tried: tried)
    }

    // MARK: 内部

    /// 请求指定 QuickConnect 端点；不同 DSM/区域端点接受的字段略有差异，因此串行尝试多种 body。
    private func postServerInfo(host: String, id: String, preferred: ServerProfile.Scheme) async throws -> [[String: Any]] {
        guard let url = URL(string: "https://\(host)/Serv.php") else {
            throw ResolveError.invalidResponse(detail: "URL")
        }
        let firstPortal = preferred == .https ? "dsm_portal_https" : "dsm_portal"
        let secondPortal = preferred == .https ? "dsm_portal" : "dsm_portal_https"
        let safeID = jsonEscaped(id)
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
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 12
        let session = URLSession(configuration: cfg)

        let bodyStrings = [
            #"[{"version":1,"command":"get_server_info","stop_when_error":false,"stop_when_success":false,"id":"\#(firstPortal)","serverID":"\#(safeID)","server_id":"\#(safeID)","is_gofile":false},{"version":1,"command":"get_server_info","stop_when_error":false,"stop_when_success":false,"id":"\#(secondPortal)","serverID":"\#(safeID)","server_id":"\#(safeID)","is_gofile":false}]"#,
            #"{"version":1,"command":"get_server_info","stop_when_error":false,"stop_when_success":false,"id":"\#(firstPortal)","serverID":"\#(safeID)","server_id":"\#(safeID)","is_gofile":false}"#,
            #"{"version":1,"command":"get_server_info","stop_when_error":false,"stop_when_success":false,"id":"\#(safeID)","serverID":"\#(safeID)","server_id":"\#(safeID)","service":"\#(firstPortal)","is_gofile":false}"#
        ]

        var lastObjects: [[String: Any]]?
        for bodyString in bodyStrings {
            req.httpBody = bodyString.data(using: .utf8)
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw ResolveError.invalidResponse(detail: "\(host) HTTP \(code)")
            }
            let decoded = try JSONSerialization.jsonObject(with: data)
            let objects: [[String: Any]]
            if let array = decoded as? [[String: Any]] {
                objects = array
            } else if let dict = decoded as? [String: Any] {
                objects = [dict]
            } else {
                let preview = String(data: data.prefix(120), encoding: .utf8) ?? "<binary>"
                throw ResolveError.invalidResponse(detail: "\(host) JSON: \(preview)")
            }
            if objects.contains(where: { ($0["errno"] as? Int ?? 0) == 0 }) { return objects }
            lastObjects = objects
        }
        guard let lastObjects else { throw ResolveError.invalidResponse(detail: "\(host) empty") }
        return lastObjects
    }

    /// 转义手写 JSON 里的字符串字段。
    private func jsonEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// 从 QuickConnect 响应里找出当前 DSM portal 对应的 service 字段。
    private func pickService(from obj: [String: Any], server: [String: Any], portalID: String) -> [String: Any] {
        let containers = [obj["service"], obj["services"], server["service"], server["services"]]
        for container in containers {
            if let service = serviceDict(from: container, portalID: portalID) {
                return service
            }
        }
        return [:]
    }

    /// 兼容字典、数组和直接 service 对象三种返回形态。
    private func serviceDict(from value: Any?, portalID: String) -> [String: Any]? {
        if let dict = value as? [String: Any] {
            if let direct = dict[portalID] as? [String: Any] { return direct }
            if (dict["id"] as? String) == portalID || (dict["service"] as? String) == portalID { return dict }
            if looksLikeService(dict) { return dict }
            for item in dict.values {
                if let found = serviceDict(from: item, portalID: portalID) { return found }
            }
        }
        if let array = value as? [[String: Any]] {
            for item in array {
                if let found = serviceDict(from: item, portalID: portalID) { return found }
            }
        }
        return nil
    }

    /// 判断一个字典是否就是 QuickConnect 返回的 service 对象。
    private func looksLikeService(_ dict: [String: Any]) -> Bool {
        let serviceKeys = ["port", "ext_port", "ext_port_https", "pingpong", "pingpong_desc"]
        return serviceKeys.contains { dict[$0] != nil }
    }

    /// 按可达性优先级从 server/service 字段里生成登录候选地址。
    private func pick(response: [String: Any], server: [String: Any], service: [String: Any], preferred: ServerProfile.Scheme) throws -> Resolved {
        // 端口：优先按通道字段；0 视为无效；缺失再用 service.port
        func nonZero(_ v: Any?) -> Int? {
            if let i = v as? Int, i > 0 { return i }
            if let n = v as? NSNumber, n.intValue > 0 { return n.intValue }
            if let s = v as? String, let i = Int(s), i > 0 { return i }
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

        // 候选地址优先级：pingpong_desc（群晖探测出的可达 host:port）
        //                > smartdns（QuickConnect 智能解析域名）
        //                > ddns（用户自配的群晖 DDNS）
        //                > external.ip / external.ipv6（公网 IP）
        //                > interface[].ip（内网 IP，只在与 NAS 同网时可达）
        var candidates: [(host: String, port: Int?)] = []
        for item in stringArray(service["pingpong_desc"]) {
            if let pair = splitHostPort(item) {
                candidates.append(pair)
            }
        }
        appendSmartDNS(response["smartdns"], to: &candidates)
        appendSmartDNS(server["smartdns"], to: &candidates)
        if let ddns = server["ddns"] as? String, !ddns.isEmpty, ddns != "NULL" {
            candidates.append((ddns, nil))
        }
        if let ddns = (server["ddns"] as? [String: Any])?["hostname"] as? String, !ddns.isEmpty, ddns != "NULL" {
            candidates.append((ddns, nil))
        }
        let external = (server["external"] as? [String: Any]) ?? [:]
        if let v4 = external["ip"] as? String, !v4.isEmpty { candidates.append((v4, nil)) }
        if let v6 = external["ipv6"] as? String, !v6.isEmpty, v6 != "::" { candidates.append((v6, nil)) }
        if let fqdn = server["fqdn"] as? String, !fqdn.isEmpty, fqdn != "NULL" {
            candidates.append((fqdn, nil))
        }
        if let interfaces = server["interface"] as? [[String: Any]] {
            for iface in interfaces {
                if let ip = iface["ip"] as? String, !ip.isEmpty { candidates.append((ip, nil)) }
            }
        }

        var seen = Set<String>()
        let resolved = candidates.compactMap { item -> Candidate? in
            let key = "\(scheme.rawValue)://\(item.host):\(item.port ?? port)"
            guard seen.insert(key).inserted else { return nil }
            return Candidate(host: item.host, port: item.port ?? port, scheme: scheme)
        }
        guard !resolved.isEmpty else {
            throw ResolveError.noHost
        }
        return Resolved(candidates: resolved)
    }

    /// 从 smartdns 字段中抽取直连域名。
    private func appendSmartDNS(_ value: Any?, to candidates: inout [(host: String, port: Int?)]) {
        if let host = value as? String, !host.isEmpty {
            candidates.append((host, nil))
        }
        if let dict = value as? [String: Any] {
            if let host = dict["host"] as? String, !host.isEmpty {
                candidates.append((host, nil))
            }
            for key in ["lan", "wan", "lanv6"] {
                for host in stringArray(dict[key]) {
                    candidates.append((host, nil))
                }
            }
        }
    }

    /// 兼容字符串数组与单个字符串两种 QuickConnect 字段。
    private func stringArray(_ value: Any?) -> [String] {
        if let array = value as? [String] { return array }
        if let string = value as? String { return [string] }
        return []
    }

    /// 拆分 `host:port` 字符串；不能解析端口时回落为裸 host。
    private func splitHostPort(_ value: String) -> (host: String, port: Int?)? {
        guard !value.isEmpty else { return nil }
        let parts = value.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count > 1, let port = Int(parts.last ?? "") else {
            return (value, nil)
        }
        let host = parts.dropLast().joined(separator: ":")
        return host.isEmpty ? nil : (host, port)
    }
}
