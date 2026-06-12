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
        ZStack(alignment: .bottom) {
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
            .onAppear {
                // 绑定播放引擎到当前 client。
                playback.apiClient = session.client
            }
            .onChange(of: session.client) { _, newClient in
                playback.apiClient = newClient
            }

            if playback.currentSong != nil {
                MiniPlayerBar(onTap: { showFullPlayer = true })
                    .padding(.horizontal, Metrics.s)
                    .padding(.bottom, 56)   // 让位给 TabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: playback.currentSong)
    }
}
