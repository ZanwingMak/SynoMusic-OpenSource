import SwiftUI

/// 喜欢的歌曲列表：使用本地快照，无需登录也能查看。
struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var playback: PlaybackEngine

    var body: some View {
        Group {
            if favorites.snapshots.isEmpty {
                EmptyStateView(
                    systemImage: "heart",
                    title: "还没有喜欢的歌曲",
                    message: "在播放器或歌曲长按菜单点击 ❤️，会出现在这里。"
                )
            } else {
                ScrollView {
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
                    .padding(.horizontal, Metrics.l)
                    .padding(.top, Metrics.s)

                    SongListSection(songs: favorites.snapshots) { idx in
                        playback.play(queue: favorites.snapshots, startAt: idx)
                    }
                    .padding(.horizontal, Metrics.l)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("我喜欢的")
        .toolbar {
            if !favorites.snapshots.isEmpty {
                Menu {
                    Button(role: .destructive) { favorites.clear() } label: {
                        Label("清空全部", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
