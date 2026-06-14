import SwiftUI

struct AllGenresView: View {
    @EnvironmentObject private var session: AppSession
    @State private var genres: [Genre] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && genres.isEmpty {
                LoadingState()
            } else if let err = error {
                ErrorStateView(title: "加载失败", message: err) { Task { await load() } }
            } else {
                List(genres) { g in
                    NavigationLink(value: BrowseRoute.genre(g)) {
                        HStack {
                            Image(systemName: "guitars.fill")
                                .foregroundStyle(Theme.accent)
                                .frame(width: 24)
                            Text(g.name).font(.nocBody)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("流派")
        .task { await load() }
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.genres = try await api.listGenres(limit: 500) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}

struct GenreDetailView: View {
    @EnvironmentObject private var session: AppSession
    let genre: Genre
    @State private var albums: [Album] = []
    @State private var isLoading = false
    @State private var error: String?
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Metrics.m)]

    var body: some View {
        ScrollView {
            if isLoading && albums.isEmpty {
                LoadingState().frame(height: 240)
            } else if let err = error {
                ErrorStateView(title: "加载失败", message: err) { Task { await load() } }.frame(height: 240)
            } else {
                LazyVGrid(columns: columns, spacing: Metrics.l) {
                    ForEach(albums) { a in
                        NavigationLink(value: BrowseRoute.album(a)) {
                            AlbumCell(album: a)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Metrics.l)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(genre.name)
        .task { await load() }
    }

    private func load() async {
        guard let api = session.client?.audioStation else { return }
        isLoading = true; defer { isLoading = false }
        do { self.albums = try await api.listAlbums(limit: 500, genre: genre.name) }
        catch { self.error = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription }
    }
}
