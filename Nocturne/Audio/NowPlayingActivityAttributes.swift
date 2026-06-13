import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// 灵动岛 / 锁屏胶囊的数据载体。
/// 主 App 与 NocturneLive Widget Extension 共享此文件。
public struct NowPlayingActivityAttributes: ActivityAttributes {

    public typealias NowPlayingState = ContentState

    public struct ContentState: Codable, Hashable, Sendable {
        public var title: String
        public var artist: String
        public var album: String?
        public var isPlaying: Bool
        public var elapsed: TimeInterval
        public var duration: TimeInterval
        public var coverURL: String?

        public init(
            title: String,
            artist: String,
            album: String?,
            isPlaying: Bool,
            elapsed: TimeInterval,
            duration: TimeInterval,
            coverURL: String?
        ) {
            self.title = title
            self.artist = artist
            self.album = album
            self.isPlaying = isPlaying
            self.elapsed = elapsed
            self.duration = duration
            self.coverURL = coverURL
        }
    }

    public var sessionStartedAt: Date

    public init(sessionStartedAt: Date) {
        self.sessionStartedAt = sessionStartedAt
    }
}
#endif
