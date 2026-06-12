import SwiftUI

/// 登录流程：先选择/新增服务器，再输入密码登录。
struct LoginFlowView: View {
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var session: AppSession
    @State private var path = NavigationPath()
    @State private var editingProfile: ServerProfile?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // 背景层：渐变 + 噪点
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.06, blue: 0.18),
                        Color(red: 0.04, green: 0.02, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                FloatingAuraBackground()
                    .opacity(0.55)
                    .blur(radius: 30)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Metrics.l) {
                        BrandHeader()
                            .padding(.top, 60)

                        if serverStore.profiles.isEmpty {
                            EmptyServerCard {
                                editingProfile = ServerProfile(host: "", username: "")
                            }
                        } else {
                            VStack(spacing: Metrics.s) {
                                ForEach(serverStore.profiles) { profile in
                                    Button {
                                        path.append(profile)
                                    } label: {
                                        ServerRow(profile: profile)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Button {
                                editingProfile = ServerProfile(host: "", username: "")
                            } label: {
                                Label("添加服务器", systemImage: "plus")
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.top, Metrics.s)
                        }
                    }
                    .padding(.horizontal, Metrics.l)
                    .padding(.bottom, Metrics.xxl)
                }
            }
            .navigationDestination(for: ServerProfile.self) { profile in
                LoginView(profile: profile)
            }
            .sheet(item: $editingProfile) { profile in
                ServerEditorView(profile: profile)
                    .presentationDetents([.large])
            }
            .preferredColorScheme(.dark)
        }
    }
}

// MARK: 子组件

private struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.3), radius: 24, y: 12)
                Image(systemName: "waveform")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("Nocturne")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("你的群晖音乐，私人夜曲。")
                .font(.nocCaption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

private struct EmptyServerCard: View {
    var onAdd: () -> Void
    var body: some View {
        GlassPanel(cornerRadius: Theme.cornerHero) {
            VStack(spacing: Metrics.m) {
                Image(systemName: "externaldrive.connected.to.line.below")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.75))
                Text("还没有连接的 NAS")
                    .font(.nocSection)
                    .foregroundStyle(.white)
                Text("添加你的群晖服务器，开始无限聆听。")
                    .font(.nocCaption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                Button("添加服务器", action: onAdd)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, Metrics.s)
            }
            .padding(Metrics.l)
        }
    }
}

private struct ServerRow: View {
    let profile: ServerProfile
    var body: some View {
        GlassPanel(cornerRadius: Theme.cornerCard) {
            HStack(spacing: Metrics.m) {
                Image(systemName: "server.rack")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.nocBody.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(profile.displayURL)
                        .font(.nocLabel)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, Metrics.m)
            .padding(.vertical, Metrics.m)
        }
    }
}

/// 浮动彩色光晕，给登录页加一点电影感。
private struct FloatingAuraBackground: View {
    @State private var t: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.42, blue: 0.65))
                    .frame(width: geo.size.width * 0.8)
                    .offset(x: -100 + sin(t) * 60, y: -120 + cos(t * 0.8) * 50)
                Circle()
                    .fill(Color(red: 0.55, green: 0.35, blue: 0.95))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: 120 + cos(t * 0.6) * 70, y: 220 + sin(t * 0.5) * 80)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: true)) {
                t = .pi * 2
            }
        }
        .allowsHitTesting(false)
    }
}
