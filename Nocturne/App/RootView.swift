import SwiftUI

/// 根视图：根据是否已登录决定显示主框架或登录流程。
struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @State private var showFullPlayer: Bool = false

    var body: some View {
        ZStack {
            if session.isLoggedIn {
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
    }
}
