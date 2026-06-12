import Foundation

/// 群晖 Web API 客户端：负责会话、URL 构造、请求执行、统一错误处理。
///
/// 用法：
/// 1. 创建实例并 `login(...)`，成功后内部持有 `sid`。
/// 2. 使用 `audioStation` 调用 Audio Station 接口。
///
/// 并发性：sid 用锁保护；URLSession 自身线程安全。整体作为引用类型在 main actor 持有但允许跨 actor 调用。
final class SynologyClient: @unchecked Sendable, Equatable {
    let profile: ServerProfile
    private let session: URLSession
    private var _sid: String?
    private let sidLock = NSLock()
    private let decoder: JSONDecoder

    /// 引用相等：用于 `onChange(of:)`。
    static func == (lhs: SynologyClient, rhs: SynologyClient) -> Bool {
        lhs === rhs
    }

    init(profile: ServerProfile) {
        self.profile = profile

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 60
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true

        if profile.ignoreInvalidCertificate && profile.scheme == .https {
            self.session = URLSession(
                configuration: cfg,
                delegate: PermissiveCertDelegate(),
                delegateQueue: nil
            )
        } else {
            self.session = URLSession(configuration: cfg)
        }

        self.decoder = JSONDecoder()
    }

    /// 当前是否已登录。
    var isAuthenticated: Bool { sid != nil }

    /// 当前会话 ID。
    var sessionID: String? { sid }

    /// 线程安全地读写 sid。
    private var sid: String? {
        get { sidLock.lock(); defer { sidLock.unlock() }; return _sid }
        set { sidLock.lock(); _sid = newValue; sidLock.unlock() }
    }

    /// 内部使用：构造 webapi URL。
    func makeURL(path: String, query: [URLQueryItem]) throws -> URL {
        guard let base = profile.baseURL else { throw SynologyError.missingBaseURL }
        var components = URLComponents(url: base.appendingPathComponent("webapi/" + path), resolvingAgainstBaseURL: false)
        var items = query
        if let sid {
            items.append(URLQueryItem(name: "_sid", value: sid))
        }
        components?.queryItems = items
        guard let url = components?.url else { throw SynologyError.missingBaseURL }
        return url
    }

    /// 执行 GET 请求并解析为指定 payload。
    func request<Payload: Decodable>(
        path: String,
        query: [URLQueryItem],
        as: Payload.Type
    ) async throws -> Payload {
        let url = try makeURL(path: path, query: query)
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw SynologyError.cancelled
        } catch {
            throw SynologyError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw SynologyError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw SynologyError.http(http.statusCode)
        }

        let envelope: SynologyResponse<Payload>
        do {
            envelope = try decoder.decode(SynologyResponse<Payload>.self, from: data)
        } catch {
            throw SynologyError.decoding(error.localizedDescription)
        }

        if envelope.success, let payload = envelope.data {
            return payload
        }
        if let err = envelope.error {
            let isAuth = path.hasPrefix("auth.cgi")
            let msg = isAuth ? SynologyError.describe(authCode: err.code) : SynologyError.describe(commonCode: err.code)
            if err.code == 106 || err.code == 107 || err.code == 119 {
                // session 失效
                sid = nil
                throw SynologyError.notAuthenticated
            }
            throw SynologyError.api(code: err.code, message: msg)
        }
        throw SynologyError.invalidResponse
    }

    // MARK: 登录 / 登出

    /// 登录；成功后内部存储 sid。
    @discardableResult
    func login(password: String, otp: String? = nil) async throws -> String {
        struct LoginData: Decodable { let sid: String? }
        var items: [URLQueryItem] = [
            .init(name: "api", value: "SYNO.API.Auth"),
            .init(name: "method", value: "Login"),
            .init(name: "version", value: "6"),
            .init(name: "account", value: profile.username),
            .init(name: "passwd", value: password),
            .init(name: "session", value: "AudioStation"),
            .init(name: "format", value: "sid")
        ]
        if let otp, !otp.isEmpty {
            items.append(.init(name: "otp_code", value: otp))
        }
        let payload: LoginData = try await request(path: "auth.cgi", query: items, as: LoginData.self)
        guard let sid = payload.sid else { throw SynologyError.notAuthenticated }
        self.sid = sid
        return sid
    }

    /// 注销当前 sid。
    func logout() async {
        let items: [URLQueryItem] = [
            .init(name: "api", value: "SYNO.API.Auth"),
            .init(name: "method", value: "Logout"),
            .init(name: "version", value: "6"),
            .init(name: "session", value: "AudioStation")
        ]
        _ = try? await request(path: "auth.cgi", query: items, as: EmptyPayload.self)
        sid = nil
    }

    /// 从外部恢复一个已存在的 sid（用于免输密码恢复会话）。
    func restoreSession(sid: String) {
        self.sid = sid
    }

    // MARK: 子模块入口

    lazy var audioStation: AudioStationAPI = AudioStationAPI(client: self)
}

/// 允许自签名证书：仅当用户在 ServerProfile 显式打开时才使用。
private final class PermissiveCertDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
