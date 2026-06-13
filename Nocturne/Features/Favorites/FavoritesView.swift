import SwiftUI

/// 喜欢的歌曲列表：默认浏览模式 / 选择模式（批量编辑）。
struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playback: PlaybackEngine

    @State private var isEditing: Bool = false
    @State private var selected: Set<String> = []

    var body: some View {
        Group {
            if favorites.snapshots.isEmpty {
                EmptyStateView(
                    systemImage: "heart",
                    title: "还没有喜欢的歌曲",
                    message: "在播放器或歌曲长按菜单点击 ❤️，会出现在这里。"
                )
            } else {
                List {
                    if !isEditing {
                        actionsRow.listRowSeparator(.hidden)
                    }
                    ForEach(favorites.snapshots) { song in
                        FavoriteRow(
                            song: song,
                            isEditing: isEditing,
                            isSelected: selected.contains(song.id),
                            isCurrent: playback.currentSong?.id == song.id,
                            isPlaying: playback.isPlaying
                        ) {
                            tap(song)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(isEditing ? "已选 \(selected.count) 首" : "我喜欢的")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("完成") { exitEdit() }
                } else if !favorites.snapshots.isEmpty {
                    Menu {
                        Button { enterEdit() } label: { Label("批量编辑", systemImage: "checklist") }
                        Button(role: .destructive) { favorites.clear() } label: {
                            Label("清空全部", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isEditing { editBar }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isEditing)
    }

    // MARK: 子组件

    private var actionsRow: some View {
        HStack(spacing: Metrics.m) {
            Button {
                playback.isShuffling = false
                playback.play(queue: favorites.snapshots, startAt: 0)
            } label: {
                Label("播放", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                playback.isShuffling = true
                playback.play(queue: favorites.snapshots.shuffled(), startAt: 0)
            } label: {
                Label("随机", systemImage: "shuffle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.vertical, Metrics.s)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private var editBar: some View {
        HStack(spacing: Metrics.s) {
            Button {
                if selected.count == favorites.snapshots.count {
                    selected.removeAll()
                } else {
                    selected = Set(favorites.snapshots.map(\.id))
                }
                Haptics.tap()
            } label: {
                Label(selected.count == favorites.snapshots.count ? "全不选" : "全选",
                      systemImage: selected.count == favorites.snapshots.count
                                ? "checkmark.square" : "square")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                playSelected()
            } label: {
                Label("播放选中", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selected.isEmpty)

            Button(role: .destructive) {
                removeSelected()
            } label: {
                Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                    .background(
                        Capsule().fill(selected.isEmpty ? Color.gray.opacity(0.4) : Color.red)
                    )
            }
            .disabled(selected.isEmpty)
        }
        .padding(.horizontal, Metrics.m)
        .padding(.vertical, Metrics.s)
        .background(.ultraThinMaterial)
    }

    // MARK: 行为

    private func tap(_ song: Song) {
        if isEditing {
            if selected.contains(song.id) {
                selected.remove(song.id)
            } else {
                selected.insert(song.id)
            }
            Haptics.tap()
        } else {
            if let idx = favorites.snapshots.firstIndex(of: song) {
                playback.play(queue: favorites.snapshots, startAt: idx)
            }
        }
    }

    private func enterEdit() {
        isEditing = true
        selected.removeAll()
        Haptics.tap()
    }
    private func exitEdit() {
        isEditing = false
        selected.removeAll()
        Haptics.tap()
    }
    private func playSelected() {
        let songs = favorites.snapshots.filter { selected.contains($0.id) }
        guard !songs.isEmpty else { return }
        playback.play(queue: songs, startAt: 0)
        exitEdit()
    }
    private func removeSelected() {
        favorites.remove(ids: selected)
        Haptics.success()
        selected.removeAll()
        if favorites.snapshots.isEmpty { exitEdit() }
    }
}

/// 单首喜欢歌曲的行；编辑模式下左侧多一个圆形选择标记。
private struct FavoriteRow: View {
    @EnvironmentObject private var session: AppSession
    let song: Song
    let isEditing: Bool
    let isSelected: Bool
    let isCurrent: Bool
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Metrics.m) {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Theme.accent : .secondary)
                }
                CoverArt(
                    url: session.client?.audioStation.songCoverURL(songID: song.id),
                    cornerRadius: 6,
                    fallbackSeed: song.id
                )
                .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.nocBody.weight(.medium))
                        .foregroundStyle(isCurrent ? Theme.accent : .primary)
                        .lineLimit(1)
                    Text([song.artist, song.album].compactMap { $0 }.joined(separator: " · "))
                        .font(.nocLabel)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if isCurrent && !isEditing {
                    EqualizerIcon(isAnimating: isPlaying)
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
