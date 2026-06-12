import SwiftUI

/// 按文件夹浏览：根/子节点，文件直接点播。
struct FolderBrowseView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine

    let folder: FolderNode?
    @State private var items: [FolderNode] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && items.isEmpty {
                LoadingState()
            } else if let err = error {
                ErrorStateView(title: "加载失败", message: err) { Task { await load() } }
            } else if items.isEmpty {
                EmptyStateView(systemImage: "folder", title: "空目录", message: "这里还没有音频文件。")
            } else {
                List {
                    ForEach(items) { node in
                        if node.type == "folder" {
                            NavigationLink(value: BrowseRoute.folder(node)) {
                                FolderRow(node: node)
                            }
                        } else {
                            Button {
                                Task { await playFile(node) }
                            } label: {
                                FolderRow(node: node)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(folder?.title ?? "文件夹")
        .task { await load() }
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.items = try await api.listFolders(parentID: folder?.id) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }

    private func playFile(_ node: FolderNode) async {
        // 兜底：folder.cgi 在不同 DSM 版本上对 file 节点要么把 song_id 放 additional 里，
        // 要么直接把 node.id 当 song_id。两种都试。
        let songID = node.songID ?? node.id
        guard !songID.isEmpty else {
            playback.setStatus("无法播放：未能解析歌曲 ID")
            return
        }
        let song = Song(
            id: songID,
            title: node.title,
            album: nil, artist: nil, albumArtist: nil,
            genre: nil, composer: nil,
            trackNumber: nil, discNumber: nil, year: nil,
            duration: 0, bitrate: nil, codec: nil, filesize: nil,
            path: node.path, rating: nil
        )
        playback.play(queue: [song], startAt: 0)
    }
}

private struct FolderRow: View {
    let node: FolderNode
    var body: some View {
        HStack(spacing: Metrics.m) {
            Image(systemName: node.type == "folder" ? "folder.fill" : "music.note")
                .foregroundStyle(node.type == "folder" ? Theme.accent : .secondary)
                .frame(width: 24)
            Text(node.title).font(.nocBody).lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
