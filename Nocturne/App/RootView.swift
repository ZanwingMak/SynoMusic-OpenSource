import SwiftUI

/// 根视图：根据是否已登录决定显示主框架或登录流程。
struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @State private var showFullPlayer: Bool = false

    /// 仅 DEBUG：`-demo` 启动参数直接进入主框架，便于演示。
    private var isDemo: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demo")
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            if session.isLoggedIn || isDemo {
                MainShellView(showFullPlayer: $showFullPlayer)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                LoginFlowView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isLoggedIn)
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView(isPresented: $showFullPlayer)
                .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-fullplayer") {
                playback.play(queue: DemoMode.songs, startAt: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    playback.pause()        // 暂停以便看静态封面
                    showFullPlayer = true
                }
            }
        }
        #endif
    }

    @EnvironmentObject private var playback: PlaybackEngine
}
