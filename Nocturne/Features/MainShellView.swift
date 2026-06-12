import SwiftUI

/// 主框架：底部 Tab + 浮动迷你播放器。
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine
    @Binding var showFullPlayer: Bool
    @State private var selectedTab: Tab = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-tab=browse") { return .browse }
        if args.contains("-tab=search") { return .search }
        if args.contains("-tab=settings") { return .settings }
        #endif
        return .library
    }()

    enum Tab: Hashable {
        case library, browse, search, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { LibraryHomeView().browseRoutes() }
                .tabItem { Label("资料库", systemImage: "rectangle.stack.fill") }
                .tag(Tab.library)

            NavigationStack { BrowseRootView().browseRoutes() }
                .tabItem { Label("浏览", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.browse)

            NavigationStack { SearchView().browseRoutes() }
                .tabItem { Label("搜索", systemImage: "magnifyingglass") }
                .tag(Tab.search)

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        // 用 safeAreaInset 让 TabView 内所有滚动视图的底部自动让出迷你播放器空间，
        // 替代之前在每个页面手工塞 Color.clear(height:100) 的方式。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if playback.currentSong != nil {
                MiniPlayerBar(onTap: { showFullPlayer = true })
                    .padding(.horizontal, Metrics.s)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { playback.apiClient = session.client }
        .onChange(of: session.client) { _, newClient in
            playback.apiClient = newClient
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: playback.currentSong)
    }
}
