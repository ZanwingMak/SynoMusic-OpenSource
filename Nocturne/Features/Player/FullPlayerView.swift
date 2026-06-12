import SwiftUI
import AVKit

/// 全屏播放器：封面、波形进度条、控制条、歌词面板、队列面板。
struct FullPlayerView: View {
    @EnvironmentObject private var playback: PlaybackEngine
    @EnvironmentObject private var session: AppSession
    @Binding var isPresented: Bool
    @State private var showLyrics = false
    @State private var showQueue = false
    @State private var dominantColor: Color = Color(red: 0.18, green: 0.10, blue: 0.25)

    var body: some View {
        ZStack {
            background
            VStack(spacing: Metrics.l) {
                topBar
                Spacer(minLength: 0)
                if showLyrics {
                    LyricsPanel(lines: playback.lyrics, currentIndex: playback.currentLyricIndex)
                        .transition(.opacity)
                } else {
                    CoverHero(songID: playback.currentSong?.id, seed: playback.currentSong?.id ?? "")
                        .padding(.horizontal, Metrics.l)
                        .transition(.opacity)
                }
                Spacer(minLength: 0)
                trackInfo
                Slider(
                    value: Binding(get: { playback.currentTime }, set: { playback.seek(to: $0) }),
                    in: 0...max(playback.duration, 0.01)
                )
                .tint(.white)
                .padding(.horizontal, Metrics.l)
                HStack {
                    Text(format(playback.currentTime))
                    Spacer()
                    Text(format(max(0, playback.duration - playback.currentTime)).withMinus)
                }
                .font(.nocLabel.monospacedDigit())
                .foregroundStyle(.white.opacity(0.65))
                .padding(.horizontal, Metrics.l)

                controlBar.padding(.top, Metrics.s)

                bottomTools.padding(.bottom, Metrics.m)
            }
            .padding(.top, Metrics.l)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showQueue) {
            QueuePanel().presentationDetents([.medium, .large])
        }
    }

    // MARK: 子组件

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [dominantColor, Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            FloatingBlobs().opacity(0.5).blur(radius: 80).ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.6), value: dominantColor)
    }

    private var topBar: some View {
        HStack {
            Button { isPresented = false } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.12), in: Circle())
            }
            Spacer()
            VStack(spacing: 2) {
                Text("正在播放").font(.nocLabel).foregroundStyle(.white.opacity(0.6))
                Text(playback.currentSong?.album ?? "")
                    .font(.nocLabel.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer()
            Menu {
                Button {
                    if let song = playback.currentSong { playback.appendNext(song) }
                } label: { Label("加入队列", systemImage: "text.line.first.and.arrowtriangle.forward") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.12), in: Circle())
            }
        }
        .padding(.horizontal, Metrics.l)
    }

    private var trackInfo: some View {
        VStack(spacing: 6) {
            Text(playback.currentSong?.title ?? "")
                .font(.nocTitleHero)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, Metrics.l)
            Text(playback.currentSong?.artist ?? "")
                .font(.nocBody)
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
        }
    }

    private var controlBar: some View {
        HStack(spacing: 36) {
            CircleIconButton(systemName: "backward.fill", size: 52) { playback.previous() }
            Button {
                Haptics.soft()
                playback.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.black)
                }
            }
            .buttonStyle(.plain)
            CircleIconButton(systemName: "forward.fill", size: 52) { playback.next() }
        }
    }

    private var bottomTools: some View {
        HStack {
            Button { playback.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(playback.isShuffling ? Theme.accent : .white.opacity(0.75))
            }
            Spacer()
            Button { withAnimation { showLyrics.toggle() } } label: {
                Image(systemName: showLyrics ? "music.note" : "quote.bubble.fill")
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            AirPlayButton()
                .frame(width: 36, height: 36)
            Spacer()
            Button { showQueue = true } label: {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.white.opacity(0.85))
            }
            Spacer()
            Button { playback.cycleRepeatMode() } label: {
                Image(systemName: repeatIcon)
                    .foregroundStyle(playback.repeatMode == .off ? .white.opacity(0.75) : Theme.accent)
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .padding(.horizontal, Metrics.xl)
    }

    private var repeatIcon: String {
        switch playback.repeatMode {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    private func format(_ s: TimeInterval) -> String {
        let total = max(0, Int(s))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private extension String {
    /// 显示剩余时长时加负号。
    var withMinus: String { "-" + self }
}

// MARK: 封面英雄区

private struct CoverHero: View {
    @EnvironmentObject private var session: AppSession
    let songID: String?
    let seed: String
    var body: some View {
        CoverArt(
            url: songID.flatMap { session.client?.audioStation.songCoverURL(songID: $0) },
            cornerRadius: Theme.cornerHero,
            fallbackSeed: seed
        )
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: .black.opacity(0.35), radius: 40, y: 16)
        .padding(.horizontal, 12)
    }
}

// MARK: 歌词面板

private struct LyricsPanel: View {
    let lines: [LyricLine]
    let currentIndex: Int?

    var body: some View {
        Group {
            if lines.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("暂无歌词").font(.nocBody).foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(Array(lines.enumerated()), id: \.element.id) { idx, line in
                                Text(line.text.isEmpty ? "♪" : line.text)
                                    .font(.system(size: idx == currentIndex ? 22 : 18, weight: idx == currentIndex ? .bold : .regular, design: .rounded))
                                    .foregroundStyle(idx == currentIndex ? .white : .white.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                    .id(idx)
                                    .animation(.easeInOut(duration: 0.25), value: currentIndex)
                            }
                        }
                        .padding(.horizontal, Metrics.l)
                        .padding(.vertical, 40)
                    }
                    .onChange(of: currentIndex) { _, idx in
                        guard let idx else { return }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            proxy.scrollTo(idx, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

// MARK: 队列面板

private struct QueuePanel: View {
    @EnvironmentObject private var playback: PlaybackEngine
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section(playback.isShuffling ? "随机播放队列" : "播放队列") {
                    ForEach(Array(playback.queue.enumerated()), id: \.element.id) { idx, song in
                        Button {
                            Haptics.tap()
                            playback.playItem(at: idx)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title).font(.nocBody)
                                        .foregroundStyle(idx == playback.currentIndex ? Theme.accent : .primary)
                                    Text(song.artist ?? "").font(.nocLabel).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if idx == playback.currentIndex {
                                    EqualizerIcon(isAnimating: playback.isPlaying)
                                        .frame(width: 18, height: 18)
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { from, to in
                        playback.moveInQueue(from: from, to: to)
                    }
                    .onDelete { idx in
                        if let i = idx.first { playback.removeFromQueue(at: i) }
                    }
                }
            }
            .navigationTitle("队列")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }
}

// MARK: AirPlay 按钮包装

private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = .white
        v.activeTintColor = UIColor(Theme.accent)
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: 背景光斑

private struct FloatingBlobs: View {
    @State private var t: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.5))
                    .frame(width: geo.size.width * 0.9)
                    .offset(x: -80 + sin(t) * 40, y: -180 + cos(t * 0.7) * 60)
                Circle()
                    .fill(Color.pink.opacity(0.5))
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: 100 + cos(t * 0.5) * 60, y: 260 + sin(t * 0.6) * 80)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 16).repeatForever(autoreverses: true)) {
                t = .pi * 2
            }
        }
    }
}
