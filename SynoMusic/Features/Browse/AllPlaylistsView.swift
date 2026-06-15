import SwiftUI

struct AllPlaylistsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && playlists.isEmpty {
                LoadingState()
            } else if let err = error {
                ErrorStateView(title: "加载失败".t, message: err) { Task { await load() } }
            } else if playlists.isEmpty {
                EmptyStateView(systemImage: "music.note.list", title: "暂无播放列表".t, message: "在 Audio Station 中创建播放列表，会出现在这里。")
            } else {
                List {
                    ForEach(playlists) { p in
                        NavigationLink(value: BrowseRoute.playlist(p)) {
                            HStack(spacing: Metrics.m) {
                                Image(systemName: p.isSmart ? "sparkles" : "music.note.list")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 44, height: 44)
                                    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(p.name).font(.nocBody.weight(.medium))
                                    if let c = p.songCount {
                                        Text("\(c) 首歌").font(.nocLabel).foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("播放列表".t)
        .task { await load() }
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.playlists = try await api.listPlaylists() }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}
