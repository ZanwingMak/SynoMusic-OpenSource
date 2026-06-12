import SwiftUI

/// 应用入口：装配根环境对象并展示首屏。
@main
struct NocturneApp: App {
    /// 服务器仓库：管理已配置的群晖服务器列表与凭证。
    @StateObject private var serverStore = ServerStore()
    /// 播放引擎：全局共享，保证迷你播放器在跨页面时状态一致。
    @StateObject private var playback = PlaybackEngine()
    /// 当前会话：保存登录后的 Synology 客户端句柄；未登录时为 nil。
    @StateObject private var session = AppSession()
    /// 喜欢的歌曲仓库（本地 UserDefaults，含离线快照）。
    @StateObject private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(serverStore)
                .environmentObject(playback)
                .environmentObject(session)
                .environmentObject(favorites)
                .tint(Theme.accent)
                .preferredColorScheme(nil)
        }
    }
}
