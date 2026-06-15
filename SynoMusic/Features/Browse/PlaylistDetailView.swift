import SwiftUI

struct PlaylistDetailView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine
    let playlist: Playlist
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Metrics.l) {
                header
                actions
                if isLoading && songs.isEmpty {
                    LoadingState().frame(height: 200)
                } else if let err = error {
                    ErrorStateView(title: "加载失败".t, message: err) { Task { await load() } }.frame(height: 200)
                } else {
                    SongListSection(songs: songs) { idx in
                        playback.play(queue: songs, startAt: idx)
                    }
                }
            }
            .padding(.horizontal, Metrics.l)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var header: some View {
        VStack(spacing: Metrics.m) {
            ZStack {
                LinearGradient(colors: [
                    Color(red: 0.95, green: 0.6, blue: 0.4),
                    Color(red: 0.7, green: 0.3, blue: 0.6)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: playlist.isSmart ? "sparkles" : "music.note.list")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerHero, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 28, y: 16)
            .padding(.top, Metrics.l)

            VStack(spacing: 4) {
                Text(playlist.name).font(.nocTitle)
                if let c = playlist.songCount {
                    Text("\(c) 首歌 · \(playlist.isSmart ? "智能列表" : "普通列表")")
                        .font(.nocCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: Metrics.m) {
            Button {
                playback.isShuffling = false
                playback.play(queue: songs, startAt: 0)
            } label: { Label("播放".t, systemImage: "play.fill") }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(songs.isEmpty)
            Button {
                playback.isShuffling = true
                playback.play(queue: songs.shuffled(), startAt: 0)
            } label: { Label("随机".t, systemImage: "shuffle") }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(songs.isEmpty)
        }
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.songs = try await api.playlistSongs(id: playlist.id) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}
