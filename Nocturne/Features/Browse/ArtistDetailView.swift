import SwiftUI

/// 艺术家详情：列出其全部专辑。
struct ArtistDetailView: View {
    @EnvironmentObject private var session: AppSession
    let artist: Artist
    @State private var albums: [Album] = []
    @State private var isLoading = false
    @State private var error: String?
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Metrics.m)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.l) {
                header
                if isLoading && albums.isEmpty {
                    LoadingState().frame(height: 200)
                } else if let err = error {
                    ErrorStateView(title: "加载失败", message: err) { Task { await load() } }
                        .frame(height: 200)
                } else {
                    LazyVGrid(columns: columns, spacing: Metrics.l) {
                        ForEach(albums) { album in
                            NavigationLink(value: BrowseRoute.album(album)) {
                                AlbumCell(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, Metrics.l)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.large)
        .task { await load() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: [
                    Color(red: 0.95, green: 0.42, blue: 0.65),
                    Color(red: 0.55, green: 0.35, blue: 0.95)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 140, height: 140)
                .overlay(
                    Text(String(artist.name.prefix(1)).uppercased())
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                )
                .padding(.top, Metrics.l)
            if let count = artist.albumCount, count > 0 {
                Text("\(count) 张专辑")
                    .font(.nocCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.albums = try await api.listAlbums(limit: 500, artist: artist.name) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}
