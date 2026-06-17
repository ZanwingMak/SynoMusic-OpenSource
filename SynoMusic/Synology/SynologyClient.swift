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
        cfg.waitsForConnectivity = false
        cfg.timeoutIntervalForRequest = 12
        cfg.timeoutIntervalForResource = 24
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
        req.timeoutInterval = 12

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

        if envelope.success {
            if let payload = envelope.data {
                return payload
            }
            if Payload.self == EmptyPayload.self {
                return EmptyPayload() as! Payload
            }
        }
        if let err = envelope.error {
            // 通过 query item 中 api=SYNO.API.Auth 判断是否走认证码表
            let isAuth = query.contains(where: { $0.name == "api" && $0.value == "SYNO.API.Auth" })
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
        // DSM 7+ 推荐 entry.cgi；entry.cgi 同时兼容 DSM 6。
        let payload: LoginData = try await request(path: "entry.cgi", query: items, as: LoginData.self)
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
        _ = try? await request(path: "entry.cgi", query: items, as: EmptyPayload.self)
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
private final class PermissiveCertDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    /// 处理 session 级 TLS 证书挑战，允许用户已确认的自签名证书继续连接。
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        complete(challenge, completionHandler: completionHandler)
    }

    /// 处理 task 级 TLS 证书挑战，覆盖 iOS 在 `data(for:)` 下分发到 task delegate 的情况。
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        complete(challenge, completionHandler: completionHandler)
    }

    /// 根据认证类型决定是否信任当前服务器证书。
    private func complete(
        _ challenge: URLAuthenticationChallenge,
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

/// 登录辅助：统一处理 QuickConnect 解析、证书域名不匹配重试与普通登录。
enum SynologyLoginHelper {
    typealias ProgressReporter = @MainActor @Sendable (String) -> Void

    /// 准备档案并登录，成功时返回已认证 client 和可能更新过的档案。
    static func login(
        profile: ServerProfile,
        password: String,
        otp: String? = nil,
        report: ProgressReporter? = nil
    ) async throws -> (client: SynologyClient, profile: ServerProfile) {
        let profiles = try await resolvedProfiles(for: profile, report: report)
        var lastError: Error?
        for (index, loginProfile) in profiles.enumerated() {
            if index > 0, let report {
                let message = await MainActor.run {
                    LanguageManager.shared.t("正在尝试备用地址") + " \(index + 1)/\(profiles.count)…"
                }
                await report(message)
            }
            do {
                return try await loginSingleCandidate(profile: loginProfile, password: password, otp: otp, report: report)
            } catch {
                if !profile.isQuickConnect || !shouldTryNextQuickConnectCandidate(error) {
                    throw error
                }
                lastError = error
            }
        }
        throw lastError ?? SynologyError.invalidResponse
    }

    /// 用单个已解析档案执行登录，必要时对 HTTPS 自签证书自动重试一次。
    private static func loginSingleCandidate(
        profile: ServerProfile,
        password: String,
        otp: String?,
        report: ProgressReporter?
    ) async throws -> (client: SynologyClient, profile: ServerProfile) {
        var loginProfile = profile
        let client = SynologyClient(profile: loginProfile)
        do {
            _ = try await withTimeout(seconds: 14) {
                try await client.login(password: password, otp: otp)
            }
            return (client, loginProfile)
        } catch let error as SynologyError where shouldRetryTrustingCertificate(error, profile: loginProfile) {
            loginProfile.ignoreInvalidCertificate = true
            if let report { await report("正在连接...") }
            let retryClient = SynologyClient(profile: loginProfile)
            _ = try await withTimeout(seconds: 14) {
                try await retryClient.login(password: password, otp: otp)
            }
            return (retryClient, loginProfile)
        }
    }

    /// 给单个候选地址的登录过程加上硬超时，避免 URLSession 在异常网络下让 UI 长时间停在连接中。
    private static func withTimeout<T: Sendable>(
        seconds: Double,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw SynologyError.network("连接超时，请检查 QuickConnect 网络或稍后重试")
            }
            guard let result = try await group.next() else {
                throw SynologyError.cancelled
            }
            group.cancelAll()
            return result
        }
    }

    /// QuickConnect 档案每次登录前重新解析为多个候选；直连档案原样返回。
    private static func resolvedProfiles(
        for profile: ServerProfile,
        report: ProgressReporter?
    ) async throws -> [ServerProfile] {
        guard profile.isQuickConnect else { return [profile] }
        let rawID = profile.quickConnectID.isEmpty ? profile.host : profile.quickConnectID
        let id = QuickConnectResolver.strip(rawID)
        let resolved = try await QuickConnectResolver().resolve(
            id,
            preferred: .https,
            report: report
        )
        return resolved.candidates.map { candidate in
            var copy = profile
            copy.quickConnectID = id
            copy.host = candidate.host
            copy.port = candidate.port
            copy.scheme = candidate.scheme
            if copy.scheme == .https {
                copy.ignoreInvalidCertificate = true
            }
            return copy
        }
    }

    /// 只刷新 QuickConnect 解析出的设备地址，不执行账号登录。
    static func refreshQuickConnectAddress(
        for profile: ServerProfile,
        report: ProgressReporter? = nil
    ) async throws -> ServerProfile {
        guard profile.isQuickConnect else { return profile }
        let rawID = profile.quickConnectID.isEmpty ? profile.host : profile.quickConnectID
        let id = QuickConnectResolver.strip(rawID)
        let resolved = try await QuickConnectResolver().resolve(
            id,
            preferred: .https,
            report: report
        )
        guard let candidate = resolved.candidates.first else {
            throw QuickConnectResolver.ResolveError.noHost
        }
        var copy = profile
        copy.quickConnectID = id
        copy.host = candidate.host
        copy.port = candidate.port
        copy.scheme = candidate.scheme
        copy.ignoreInvalidCertificate = true
        return copy
    }

    /// 仅 QuickConnect HTTPS 在证书信任/域名不匹配时自动重试一次。
    private static func shouldRetryTrustingCertificate(_ error: SynologyError, profile: ServerProfile) -> Bool {
        guard profile.isQuickConnect,
              profile.scheme == .https,
              !profile.ignoreInvalidCertificate,
              case .network = error else {
            return false
        }
        return true
    }

    /// 只有网络/HTTP/解析类问题才尝试下一个 QC 候选；账号密码/OTP 等认证错误不重试。
    private static func shouldTryNextQuickConnectCandidate(_ error: Error) -> Bool {
        guard let synologyError = error as? SynologyError else { return false }
        switch synologyError {
        case .network, .http, .invalidResponse, .decoding, .missingBaseURL, .cancelled:
            return true
        case .api, .notAuthenticated:
            return false
        }
    }
}
