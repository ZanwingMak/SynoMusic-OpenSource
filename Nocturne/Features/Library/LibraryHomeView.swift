import SwiftUI

/// 资料库首页：欢迎语 + 最近添加的专辑墙 + 推荐艺术家。
struct LibraryHomeView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine
    @StateObject private var vm = LibraryHomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.l) {
                Header()
                QuickActions()
                if vm.isLoading && vm.recentAlbums.isEmpty {
                    LoadingState().frame(height: 280)
                } else if let err = vm.error {
                    ErrorStateView(title: "加载失败", message: err) { Task { await vm.load(client: session.client) } }
                        .frame(height: 280)
                } else {
                    if !vm.recentAlbums.isEmpty {
                        SectionTitle("最近添加")
                        FeaturedAlbumScroller(albums: vm.recentAlbums)
                    }
                    if !vm.albums.isEmpty {
                        SectionTitle("全部专辑")
                        AlbumGrid(albums: vm.albums)
                    }
                    if !vm.artists.isEmpty {
                        SectionTitle("艺术家")
                        ArtistRail(artists: vm.artists)
                    }
                }
            }
            .padding(.horizontal, Metrics.l)
            .padding(.top, Metrics.s)
        }
        .refreshable { await vm.load(client: session.client, force: true) }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Nocturne")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: BrowseRoute.localPlaylists) {
                    Image(systemName: "music.note.list")
                        .accessibilityLabel("我的歌单")
                }
                NavigationLink(value: BrowseRoute.radio) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .accessibilityLabel("电台")
                }
                NavigationLink(value: BrowseRoute.settings) {
                    Image(systemName: "gearshape")
                        .accessibilityLabel("设置")
                }
            }
        }
        .task { await vm.load(client: session.client) }
    }
}

// MARK: 子组件

private struct Header: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(timeGreeting())
                .font(.nocCaption)
                .foregroundStyle(.secondary)
            Text("听听今天该听的")
                .font(.system(.title, design: .rounded).weight(.bold))
        }
        .padding(.top, Metrics.s)
    }
    private func timeGreeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<11: return "早安"
        case 11..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<23: return "晚上好"
        default: return "夜深了"
        }
    }
}

/// 资料库首页顶部的快捷卡片横向滑动区。
private struct QuickActions: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine
    @State private var isShuffling = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.m) {
                Button { Task { await randomShuffleAll() } } label: {
                    ActionCard(
                        title: "随机歌单",
                        subtitle: isShuffling ? "正在抓取…" : "从全库抽 100 首",
                        icon: "shuffle",
                        gradient: [Color(red: 0.95, green: 0.42, blue: 0.65), Color(red: 0.55, green: 0.20, blue: 0.95)]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: BrowseRoute.favorites) {
                    ActionCard(
                        title: "我喜欢的",
                        subtitle: "本地收藏",
                        icon: "heart.fill",
                        gradient: [Color(red: 0.99, green: 0.4, blue: 0.55), Color(red: 0.85, green: 0.15, blue: 0.45)]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: BrowseRoute.allSongs) {
                    ActionCard(
                        title: "所有歌曲",
                        subtitle: "整库浏览",
                        icon: "music.note",
                        gradient: [Color(red: 0.55, green: 0.4, blue: 0.95), Color(red: 0.25, green: 0.25, blue: 0.65)]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: BrowseRoute.radio) {
                    ActionCard(
                        title: "电台",
                        subtitle: "全球电台",
                        icon: "antenna.radiowaves.left.and.right",
                        gradient: [Color(red: 0.4, green: 0.85, blue: 0.7), Color(red: 0.1, green: 0.55, blue: 0.55)]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(value: BrowseRoute.allAlbums) {
                    ActionCard(
                        title: "全部专辑",
                        subtitle: "整库浏览",
                        icon: "square.stack.fill",
                        gradient: [Color(red: 0.95, green: 0.6, blue: 0.3), Color(red: 0.85, green: 0.3, blue: 0.3)]
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .scrollClipDisabled()
    }

    private func randomShuffleAll() async {
        guard let api = session.client?.audioStation else {
            playback.setStatus("请先连接服务器再随机播放")
            return
        }
        isShuffling = true
        defer { isShuffling = false }
        do {
            let songs = try await api.randomSongs(count: 100)
            guard !songs.isEmpty else {
                playback.setStatus("没有可播放的歌曲")
                return
            }
            playback.isShuffling = true
            playback.play(queue: songs, startAt: 0)
        } catch {
            playback.setStatus("随机抓取失败：\(error.localizedDescription)")
        }
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.18))
                .offset(x: 72, y: 18)
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text(title).font(.nocSection).foregroundStyle(.white)
                Text(subtitle).font(.nocLabel).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
            }
            .padding(Metrics.m)
        }
        .frame(width: 170, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerCard, style: .continuous))
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 12, y: 6)
    }
}

private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.nocSection)
            .padding(.top, Metrics.s)
    }
}

private struct FeaturedAlbumScroller: View {
    @EnvironmentObject private var session: AppSession
    let albums: [Album]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.m) {
                ForEach(albums) { album in
                    NavigationLink(value: BrowseRoute.album(album)) {
                        FeaturedAlbumCard(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }
}

private struct FeaturedAlbumCard: View {
    @EnvironmentObject private var session: AppSession
    let album: Album
    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.s) {
            CoverArt(
                url: session.client?.audioStation.albumCoverURL(album: album.name, albumArtist: album.artist),
                cornerRadius: 14,
                fallbackSeed: album.id
            )
            .frame(width: 220, height: 220)
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name)
                    .font(.nocBody.weight(.semibold))
                    .lineLimit(1)
                Text(album.displayArtist)
                    .font(.nocCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 220, alignment: .leading)
        }
    }
}

private struct AlbumGrid: View {
    let albums: [Album]
    @EnvironmentObject private var session: AppSession
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: Metrics.m)]
    var body: some View {
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

struct AlbumCell: View {
    @EnvironmentObject private var session: AppSession
    let album: Album
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CoverArt(
                url: session.client?.audioStation.albumCoverURL(album: album.name, albumArtist: album.artist),
                cornerRadius: 10,
                fallbackSeed: album.id
            )
            .aspectRatio(1, contentMode: .fit)
            Text(album.name)
                .font(.nocBody.weight(.semibold))
                .lineLimit(1)
            Text(album.displayArtist)
                .font(.nocLabel)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct ArtistRail: View {
    let artists: [Artist]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.m) {
                ForEach(artists) { artist in
                    NavigationLink(value: BrowseRoute.artist(artist)) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(
                                    colors: gradient(for: artist.name),
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .overlay(
                                    Text(artist.name.prefix(1).uppercased())
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                )
                                .frame(width: 76, height: 76)
                            Text(artist.name)
                                .font(.nocLabel)
                                .lineLimit(1)
                                .frame(width: 80)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
    }
    private func gradient(for name: String) -> [Color] {
        let hue = abs(Double(name.hashValue % 1000)) / 1000.0
        return [
            Color(hue: hue, saturation: 0.6, brightness: 0.9),
            Color(hue: (hue + 0.15).truncatingRemainder(dividingBy: 1), saturation: 0.7, brightness: 0.5)
        ]
    }
}
