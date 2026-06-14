import Foundation

/// 全球电台基础信息。
struct RadioStation: Identifiable, Hashable, Decodable {
    let stationuuid: String
    let name: String
    let url_resolved: String
    let homepage: String?
    let favicon: String?
    let country: String?
    let countrycode: String?
    let language: String?
    let tags: String?
    let codec: String?
    let bitrate: Int?

    var id: String { stationuuid }
    var streamURL: URL? { URL(string: url_resolved) }
    var faviconURL: URL? { favicon.flatMap { $0.isEmpty ? nil : URL(string: $0) } }
}

/// Radio-Browser API 客户端：基于公开 mirror，自动选择最近的可用主机。
/// 文档：https://api.radio-browser.info/
final class RadioAPI: @unchecked Sendable {

    static let shared = RadioAPI()
    private let session: URLSession
    private let decoder = JSONDecoder()
    private var baseHost: String = "de1.api.radio-browser.info"

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 12
        cfg.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: cfg)
    }

    /// 探测最近的 API mirror；失败保持默认。
    func resolveMirror() async {
        let url = URL(string: "https://all.api.radio-browser.info/json/servers")!
        guard let (data, _) = try? await session.data(from: url),
              let list = try? decoder.decode([[String: String]].self, from: data),
              let first = list.first?["name"] else { return }
        baseHost = first
    }

    /// 拉取最受欢迎的电台列表。
    func topStations(limit: Int = 60) async throws -> [RadioStation] {
        try await get(path: "stations/topvote",
                      query: [("limit", "\(limit)"), ("hidebroken", "true")])
    }

    /// 按国家代码（ISO 2 letter，如 "CN"、"US"、"JP"）筛选。
    func stations(countryCode code: String, limit: Int = 80) async throws -> [RadioStation] {
        try await get(path: "stations/bycountrycodeexact/\(code)",
                      query: [("limit", "\(limit)"),
                              ("hidebroken", "true"),
                              ("order", "votes"),
                              ("reverse", "true")])
    }

    /// 关键词搜索。
    func search(_ keyword: String, limit: Int = 50) async throws -> [RadioStation] {
        try await get(path: "stations/search",
                      query: [("name", keyword),
                              ("limit", "\(limit)"),
                              ("hidebroken", "true"),
                              ("order", "votes"),
                              ("reverse", "true")])
    }

    /// 按标签（流派）。
    func stations(tag: String, limit: Int = 60) async throws -> [RadioStation] {
        try await get(path: "stations/bytagexact/\(tag)",
                      query: [("limit", "\(limit)"),
                              ("hidebroken", "true"),
                              ("order", "votes"),
                              ("reverse", "true")])
    }

    /// 上报点击（让 radio-browser 统计权重；失败不抛错）。
    func reportClick(_ uuid: String) async {
        let url = URL(string: "https://\(baseHost)/json/url/\(uuid)")!
        _ = try? await session.data(from: url)
    }

    // MARK: 内部

    private func get<T: Decodable>(path: String, query: [(String, String)]) async throws -> T {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = baseHost
        comps.path = "/json/\(path)"
        comps.queryItems = query.map { URLQueryItem(name: $0.0, value: $0.1) }
        guard let url = comps.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.setValue("SynoMusic/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: req)
        return try decoder.decode(T.self, from: data)
    }
}

/// 把 RadioStation 转成 Song（id 用 station uuid，title 用电台名）让 PlaybackEngine 复用流播路径。
extension RadioStation {
    func asSong() -> Song {
        Song(
            id: "radio:\(stationuuid)",
            title: name,
            album: country,
            artist: tags?.split(separator: ",").first.map(String.init),
            albumArtist: nil,
            genre: tags,
            composer: nil,
            trackNumber: nil,
            discNumber: nil,
            year: nil,
            duration: 0,
            bitrate: bitrate.map { $0 * 1000 },
            codec: codec,
            filesize: nil,
            path: url_resolved,
            rating: nil
        )
    }
}
