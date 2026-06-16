import SwiftUI
import AVKit
import UIKit

/// 全屏播放器：封面、波形进度条、控制条、歌词面板、队列面板。
struct FullPlayerView: View {
    @EnvironmentObject private var playback: PlaybackEngine
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playlists: PlaylistStore
    @EnvironmentObject private var theme: ThemeManager
    @Binding var isPresented: Bool
    @State private var showLyrics = false
    @State private var showQueue = false
    @State private var showSleep = false
    @State private var showAddToPlaylist = false
    @State private var showDeleteConfirm = false
    @State private var ratingPending: Int?
    @State private var showSongInfo = false
    @State private var showSongEdit = false
    @State private var dominantColor: Color = Color(red: 0.18, green: 0.10, blue: 0.25)

    var body: some View {
        GeometryReader { geo in
            let visualHeight = min(max(geo.size.height * 0.34, 250), 330)
            let artSide = min(geo.size.width - Metrics.xl * 2, visualHeight)
            ZStack(alignment: .top) {
                background
                VStack(spacing: 0) {
                    topBar
                        .frame(height: 52)
                        .zIndex(10)
                    Spacer(minLength: 8)
                    playbackVisual(artSide: artSide)
                        .frame(height: visualHeight)
                    Spacer(minLength: 10)
                    trackInfo
                        .frame(height: 86, alignment: .center)
                    progressSection
                        .frame(height: 56)
                    controlBar
                        .frame(height: 92)
                    bottomTools
                        .frame(height: 48)
                        .padding(.bottom, max(Metrics.s, geo.safeAreaInsets.bottom))
                }
                .padding(.top, Metrics.l)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: theme.currentID)
        .tint(theme.current.accent(in: .dark))
        .overlay(alignment: .top) {
            if let msg = playback.statusMessage {
                HStack(spacing: Metrics.s) {
                    Image(systemName: "info.circle.fill").foregroundStyle(.white)
                    Text(msg)
                        .font(.nocCaption)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                    Spacer(minLength: 4)
                    Button {
                        playback.dismissStatus()
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Metrics.m)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75), in: Capsule())
                .padding(.horizontal, Metrics.m)
                .padding(.top, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: playback.statusMessage)
        .sheet(isPresented: $showQueue) {
            QueuePanel().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSleep) {
            SleepTimerSheet(isPresented: $showSleep)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddToPlaylist) {
            if let song = playback.currentSong {
                AddToPlaylistSheet(song: song)
                    .presentationDetents([.medium, .large])
            }
        }
        .alert("删除文件".t, isPresented: $showDeleteConfirm) {
            Button("删除".t, role: .destructive) { Task { await deleteCurrent() } }
            Button("取消".t, role: .cancel) {}
        } message: {
            Text(deleteAlertMessage)
        }
        .sheet(isPresented: $showSongInfo) {
            if let song = playback.currentSong {
                SongInfoSheet(song: song)
                    .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showSongEdit) {
            if let song = playback.currentSong {
                SongEditSheet(song: song)
                    .presentationDetents([.large])
            }
        }
    }

    /// 删除确认提示文案，避免内联插值让 SwiftUI 编译器超时。
    private var deleteAlertMessage: String {
        let title = playback.currentSong?.title ?? "该歌曲".t
        return "将通过 File Station 永久删除".t + "「\(title)」" + "对应的文件。该操作不可撤销。".t
    }

    /// 调用 setrating 接口。
    private func applyRating(_ stars: Int) async {
        guard let song = playback.currentSong,
              let api = session.client?.audioStation else { return }
        do {
            try await api.setRating(songID: song.id, rating: stars)
            ratingPending = stars
            playback.updateRating(forSongID: song.id, rating: stars)
            playback.setStatus(stars == 0 ? "已清除评分".t : "已设为".t + " \(stars) " + "星".t)
            Haptics.success()
        } catch {
            playback.setStatus("评分失败".t + "：\((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
            Haptics.warning()
        }
    }

    /// 通过 File Station 删除当前歌曲文件，然后从队列中移除。
    private func deleteCurrent() async {
        guard let song = playback.currentSong,
              let api = session.client?.audioStation,
              let path = song.path, !path.isEmpty else {
            playback.setStatus("没有可删除的文件路径".t)
            return
        }
        do {
            _ = try await api.deleteFiles(paths: [path])
            playback.setStatus("删除任务已提交".t)
            // 从本地队列移除当前曲并尝试播放下一首
            if let idx = playback.queue.firstIndex(of: song) {
                playback.removeFromQueue(at: idx)
            }
            Haptics.success()
        } catch {
            playback.setStatus("删除失败".t + "：\((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
            Haptics.warning()
        }
    }

    /// 是否有任一定时停止策略已激活，决定月亮图标着色。
    private var sleepActive: Bool {
        playback.sleepRemaining != nil || playback.stopAtTrackEnd
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
                Text("正在播放".t).font(.nocLabel).foregroundStyle(.white.opacity(0.6))
                Text(playback.currentSong?.album ?? "")
                    .font(.nocLabel.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer()
            // 把更多操作抽到独立视图，仅依赖 currentSong 的 id。
            TopBarMenu(
                song: playback.currentSong,
                onAppendNext: { if let s = playback.currentSong { playback.appendNext(s) } },
                onAddToPlaylist: { showAddToPlaylist = true },
                onShowInfo: { showSongInfo = true },
                onShowEdit: { showSongEdit = true },
                currentRating: ratingPending ?? playback.currentSong?.rating,
                onRate: { stars in Task { await applyRating(stars) } },
                onDelete: { showDeleteConfirm = true }
            )
            .id(playback.currentSong?.id ?? "none")
        }
        .padding(.horizontal, Metrics.l)
        .onChange(of: playback.currentSong?.id) { _, _ in
            ratingPending = nil
        }
    }
}

/// 全屏播放器右上的菜单：用 popover + 系统液态玻璃材质渲染，位置由系统锚定。
private struct TopBarMenu: View {
    let song: Song?
    let onAppendNext: () -> Void
    let onAddToPlaylist: () -> Void
    let onShowInfo: () -> Void
    let onShowEdit: () -> Void
    let currentRating: Int?
    let onRate: (Int) -> Void
    let onDelete: () -> Void
    @State private var showMenu: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-show-player-menu")
        #else
        return false
        #endif
    }()
    @State private var showRating = false

    private let menuWidth: CGFloat = 252

    /// 当前歌曲是否允许删除文件。
    private var canDeleteCurrentSong: Bool {
        guard let song else { return false }
        return !song.id.hasPrefix("radio:") && !(song.path ?? "").isEmpty
    }

    var body: some View {
        Button {
            Haptics.tap()
            showRating = false
            showMenu = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if showMenu {
                PlayerGlassMenu {
                    menuContent
                }
                .frame(width: menuWidth)
                .offset(y: 48)
                .transition(.scale(scale: 0.96, anchor: .topTrailing).combined(with: .opacity))
                .zIndex(200)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.84), value: showMenu)
        .animation(.easeInOut(duration: 0.16), value: showRating)
        .zIndex(200)
    }

    /// popover 内的两种面板切换。
    @ViewBuilder
    private var menuContent: some View {
        if showRating {
            ratingPanel
                .transition(.opacity)
        } else {
            actionsPanel
                .transition(.opacity)
        }
    }

    /// 主菜单面板。
    private var actionsPanel: some View {
        VStack(spacing: 0) {
            PlayerMenuRow(icon: "text.line.first.and.arrowtriangle.forward", title: "加入队列".t) {
                perform(onAppendNext)
            }
            PlayerMenuRow(icon: "text.badge.plus", title: "添加到歌单…".t) {
                perform(onAddToPlaylist)
            }
            PlayerMenuRow(icon: "info.circle", title: "歌曲信息".t) {
                perform(onShowInfo)
            }
            PlayerMenuRow(icon: "square.and.pencil", title: "编辑歌曲信息".t) {
                perform(onShowEdit)
            }
            PlayerMenuRow(icon: "star", title: "评分".t, showsChevron: true) {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.18)) { showRating = true }
            }
            Divider().padding(.vertical, 4)
            PlayerMenuRow(
                icon: "trash",
                title: "删除文件…".t,
                role: .destructive,
                isEnabled: canDeleteCurrentSong
            ) {
                perform(onDelete)
            }
        }
        .padding(.vertical, 6)
    }

    /// 评分子面板。
    private var ratingPanel: some View {
        VStack(spacing: 0) {
            PlayerMenuRow(icon: "chevron.left", title: "评分".t) {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.18)) { showRating = false }
            }
            Divider().padding(.vertical, 4)
            PlayerMenuRow(icon: currentRating == 0 ? "star.slash.fill" : "star.slash", title: "清除评分".t) {
                perform { onRate(0) }
            }
            ForEach(1...5, id: \.self) { rating in
                let isSelected = currentRating == rating
                PlayerMenuRow(icon: isSelected ? "star.fill" : "star", title: "\(rating) \("星".t)") {
                    perform { onRate(rating) }
                }
            }
        }
        .padding(.vertical, 6)
    }

    /// 执行动作并关闭 popover。
    private func perform(_ action: @escaping () -> Void) {
        Haptics.tap()
        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
            showMenu = false
        }
        action()
    }
}

/// 播放器菜单玻璃容器：iOS 26 使用系统 glassEffect，旧系统退回稳定材质。
private struct PlayerGlassMenu<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    content()
                        .background {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        }
                        .glassEffect(
                            .regular.tint(Color.white.opacity(0.08)).interactive(),
                            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
                        )
                }
            } else {
                content()
                    .background {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 34, style: .continuous)
                                    .fill(Color.black.opacity(0.18))
                            }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

/// 播放器菜单单行：紧凑布局 + 按压反馈。
private struct PlayerMenuRow: View {
    enum Role {
        case normal
        case destructive
    }

    let icon: String?
    let title: String
    var role: Role = .normal
    var showsChevron: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    private let iconColor = Color(red: 0.68, green: 0.48, blue: 1.0)

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(role == .destructive ? .red : iconColor)
                        .frame(width: 20, height: 20)
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(role == .destructive ? Color(red: 1, green: 0.42, blue: 0.38) : .white.opacity(0.92))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(PlayerMenuRowButtonStyle())
        .disabled(!isEnabled)
    }
}

/// 播放器菜单行按钮样式：按下时给出缩放与玻璃高光反馈。
private struct PlayerMenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(configuration.isPressed ? Color.white.opacity(0.14) : Color.clear)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension FullPlayerView {
    /// 播放器中部视觉区域；封面和歌词共用同一个固定槽位，避免切换时挤压控件。
    @ViewBuilder
    private func playbackVisual(artSide: CGFloat) -> some View {
        ZStack {
            if showLyrics {
                LyricsPanel(lines: playback.lyrics, currentIndex: playback.currentLyricIndex)
                    .transition(.opacity)
            } else {
                CoverHero(songID: playback.currentSong?.id, seed: playback.currentSong?.id ?? "", side: artSide)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.28)) { showLyrics.toggle() }
        }
    }

    /// 播放进度区域；固定时间标签高度，避免时长变化影响控制按钮位置。
    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(get: { playback.currentTime }, set: { playback.seek(to: $0) }),
                in: 0...max(playback.duration, 0.01)
            )
            .tint(.white)
            HStack {
                Text(format(playback.currentTime))
                Spacer()
                Text(format(max(0, playback.duration - playback.currentTime)).withMinus)
            }
            .font(.nocLabel.monospacedDigit())
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.horizontal, Metrics.l)
    }

    private var trackInfo: some View {
        HStack(alignment: .center, spacing: Metrics.m) {
            VStack(alignment: .leading, spacing: 6) {
                Text(playback.currentSong?.title ?? "")
                    .font(.nocTitleHero)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(playback.currentSong?.artist ?? "")
                        .font(.nocBody)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                    qualityBadge
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contextMenu {
                Button {
                    copyToPasteboard(playback.currentSong?.title ?? "")
                } label: {
                    Label("复制歌曲名".t, systemImage: "doc.on.doc")
                }
                if let artist = playback.currentSong?.artist, !artist.isEmpty {
                    Button {
                        copyToPasteboard(artist)
                    } label: {
                        Label("复制作者".t, systemImage: "person.text.rectangle")
                    }
                }
            }
            Spacer()
            if let song = playback.currentSong {
                HStack(spacing: 14) {
                    Button {
                        showAddToPlaylist = true
                    } label: {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("加入歌单".t)

                    Button {
                        Haptics.soft()
                        playlists.toggleFavorite(song)
                    } label: {
                        Image(systemName: playlists.isFavorite(song) ? "heart.fill" : "heart")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(playlists.isFavorite(song) ? Color(red: 1, green: 0.32, blue: 0.45) : .white.opacity(0.75))
                            .scaleEffect(playlists.isFavorite(song) ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: playlists.isFavorite(song))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(playlists.isFavorite(song) ? "取消喜欢".t : "喜欢".t)
                }
                .frame(width: 82)
            }
        }
        .padding(.horizontal, Metrics.l)
    }

    /// 当前播放音质徽标。
    private var qualityBadge: some View {
        Text(playback.quality.titleKey.t)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.12), in: Capsule(style: .continuous))
            .lineLimit(1)
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
        HStack(spacing: 0) {
            bottomToolButton {
                playback.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .foregroundStyle(playback.isShuffling ? Theme.accent : .white.opacity(0.75))
            }
            bottomToolButton {
                showSleep = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "moon.zzz")
                        .foregroundStyle(sleepActive ? Theme.accent : .white.opacity(0.85))
                    if sleepActive {
                        Circle().fill(Color.green).frame(width: 7, height: 7).offset(x: 4, y: -3)
                    }
                }
            }
            bottomToolButton {
                withAnimation(.easeInOut(duration: 0.2)) { showLyrics.toggle() }
            } label: {
                Image(systemName: showLyrics ? "music.note" : "quote.bubble.fill")
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
            }
            AirPlayButton()
                .frame(width: 36, height: 36)
                .frame(maxWidth: .infinity)
            bottomToolButton {
                showQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundStyle(.white.opacity(0.85))
            }
            bottomToolButton {
                playback.cycleRepeatMode()
            } label: {
                Image(systemName: repeatIcon)
                    .foregroundStyle(playback.repeatMode == .off ? .white.opacity(0.75) : Theme.accent)
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .padding(.horizontal, Metrics.xl)
    }

    /// 底部工具栏的等宽按钮容器，保证图标切换时其它按钮不横向跳动。
    private func bottomToolButton<Content: View>(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Content
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label()
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
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

    /// 复制非空文本到剪贴板并提示用户。
    private func copyToPasteboard(_ text: String) {
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        playback.setStatus("已复制".t)
        Haptics.success()
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
    let side: CGFloat
    var body: some View {
        CoverArt(
            url: songID.flatMap { session.client?.audioStation.songCoverURL(songID: $0) },
            cornerRadius: Theme.cornerHero,
            fallbackSeed: seed
        )
        .frame(width: side, height: side)
        .shadow(color: .black.opacity(0.35), radius: 40, y: 16)
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
                    Text("暂无歌词".t).font(.nocBody).foregroundStyle(.white.opacity(0.6))
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
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.editMode) private var editMode

    /// 当前队列列表是否处于编辑模式。
    private var isEditingQueue: Bool {
        editMode?.wrappedValue.isEditing == true
    }

    var body: some View {
        NavigationStack {
            List {
                Section(playback.isShuffling ? "随机播放队列".t : "播放队列".t) {
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
            .navigationTitle("队列".t)
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.accent(in: .dark))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditingQueue ? "完成".t : "编辑".t) {
                        toggleQueueEditing()
                    }
                }
            }
        }
    }

    /// 切换队列的编辑状态；避免额外动画叠加系统列表编辑动画造成卡顿。
    private func toggleQueueEditing() {
        editMode?.wrappedValue = isEditingQueue ? .inactive : .active
    }
}

// MARK: AirPlay 按钮包装

private struct AirPlayButton: UIViewRepresentable {
    /// 创建系统 AirPlay 路由选择器，并使用当前强调色作为激活态颜色。
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = .white
        v.activeTintColor = UIColor(Theme.accent)
        return v
    }

    /// SwiftUI 刷新时同步强调色，避免切换主题后 AirPlay 激活态仍保留旧颜色。
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.activeTintColor = UIColor(Theme.accent)
    }
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
