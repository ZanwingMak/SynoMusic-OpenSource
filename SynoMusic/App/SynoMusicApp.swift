import SwiftUI

/// 应用入口：装配根环境对象并展示首屏。
@main
struct SynoMusicApp: App {
    /// 服务器仓库：管理已配置的群晖服务器列表与凭证。
    @StateObject private var serverStore = ServerStore()
    /// 播放引擎：全局共享，保证迷你播放器在跨页面时状态一致。
    @StateObject private var playback = PlaybackEngine()
    /// 当前会话：保存登录后的 Synology 客户端句柄；未登录时为 nil。
    @StateObject private var session = AppSession()
    /// 本地歌单仓库（含「我喜欢的」内置 + 用户自定义）。
    @StateObject private var playlists = PlaylistStore()
    /// 主题（accent 色 + 外观偏好）。
    @StateObject private var theme = ThemeManager.shared
    /// 多语言。
    @StateObject private var lm = LanguageManager.shared
    /// 播放偏好（后台播放 / 锁屏 / AirPlay 开关）。
    @StateObject private var playbackSettings = PlaybackSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(serverStore)
                .environmentObject(playback)
                .environmentObject(session)
                .environmentObject(playlists)
                .environmentObject(theme)
                .environmentObject(lm)
                .environmentObject(playbackSettings)
                .onAppear { playback.applyPlaybackSettings(playbackSettings) }
                .tint(theme.current.accent(in: .dark))
                .preferredColorScheme(theme.appearance.colorScheme)
                // 只对语言变化重建整树（翻译值仅在 body 重算时才会刷新）；
                // 主题强调色与 appearance 通过 .tint() 与 .preferredColorScheme()
                // 由 SwiftUI 自动传播，不需要重建，避免切换主题就跳回首页。
                .id(lm.current.rawValue)
        }
    }
}

/// 字符串便捷翻译入口：`"设置".t` 等价于 `LanguageManager.shared.t("设置")`。
extension String {
    @MainActor var t: String { LanguageManager.shared.t(self) }
}
