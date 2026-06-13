import SwiftUI

/// 根视图：根据是否已登录决定显示主框架或登录流程。
/// 启动时若有默认服务器档案且 Keychain 中存了密码，则后台静默登录。
struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var playback: PlaybackEngine
    @State private var showFullPlayer: Bool = false
    @State private var isAutoLogging: Bool = false

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
                LoginFlowView(autoLoggingIn: isAutoLogging)
                    .transition(.opacity)
            }
            // 顶部 Toast：播放/连接状态消息
            if let message = playback.statusMessage {
                StatusToast(message: message) { playback.dismissStatus() }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: session.isLoggedIn)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playback.statusMessage)
        .background(Theme.background.ignoresSafeArea())
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView(isPresented: $showFullPlayer)
                .presentationDragIndicator(.visible)
        }
        .task { await attemptAutoLogin() }
        #if DEBUG
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-fullplayer") {
                playback.play(queue: DemoMode.songs, startAt: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    playback.pause()
                    showFullPlayer = true
                }
            } else if args.contains("-miniplayer") {
                playback.play(queue: DemoMode.songs, startAt: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    playback.pause()
                }
            }
        }
        #endif
    }

    /// 启动时尝试用默认档案 + Keychain 密码静默登录。
    private func attemptAutoLogin() async {
        guard !session.isLoggedIn, !isDemo else { return }
        guard let p = serverStore.defaultProfile,
              let pwd = serverStore.password(for: p), !pwd.isEmpty else { return }
        isAutoLogging = true
        defer { isAutoLogging = false }
        let client = SynologyClient(profile: p)
        do {
            try await client.login(password: pwd)
            var updated = p
            updated.lastConnectedAt = Date()
            serverStore.upsert(updated)
            session.sign(in: client)
            Haptics.success()
        } catch {
            // 静默失败：用户进入 LoginFlowView 手动处理
            playback.setStatus("自动登录失败：\((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
        }
    }
}

/// 顶部状态条：从顶部滑入，可点关闭。
private struct StatusToast: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: Metrics.s) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.white)
                Text(message)
                    .font(.nocCaption)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Metrics.m)
            .padding(.vertical, Metrics.s + 2)
            .background(Color.black.opacity(0.78), in: Capsule())
            .padding(.horizontal, Metrics.m)
            .padding(.top, Metrics.s)
            Spacer()
        }
    }
}
