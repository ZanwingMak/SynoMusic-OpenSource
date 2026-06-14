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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(serverStore)
                .environmentObject(playback)
                .environmentObject(session)
                .environmentObject(playlists)
                .environmentObject(theme)
                .environmentObject(lm)
                .tint(theme.current.accent(in: .dark))
                .preferredColorScheme(theme.appearance.colorScheme)
                // 主题 / 外观 / 语言切换时让整棵视图树重渲染，
                // 否则 String 翻译值不会触发视图重新求值。
                .id("\(theme.currentID)-\(theme.appearance.rawValue)-\(lm.current.rawValue)")
        }
    }
}

/// 字符串便捷翻译入口：`"设置".t` 等价于 `LanguageManager.shared.t("设置")`。
extension String {
    @MainActor var t: String { LanguageManager.shared.t(self) }
}
