import SwiftUI

/// 浏览入口：分类卡片。
struct BrowseRootView: View {
    @EnvironmentObject private var session: AppSession

    private let categories: [(label: String, icon: String, route: BrowseRoute, gradient: [Color])] = [
        ("电台", "antenna.radiowaves.left.and.right", .radio, [Color(red: 0.95, green: 0.42, blue: 0.5), Color(red: 0.55, green: 0.2, blue: 0.85)]),
        ("我喜欢的", "heart.fill", .favorites, [Color(red: 0.99, green: 0.4, blue: 0.55), Color(red: 0.85, green: 0.15, blue: 0.45)]),
        ("专辑", "square.stack.fill", .allAlbums, [Color(red: 0.95, green: 0.42, blue: 0.65), Color(red: 0.7, green: 0.3, blue: 0.9)]),
        ("艺术家", "person.2.fill", .allArtists, [Color(red: 0.4, green: 0.5, blue: 0.95), Color(red: 0.2, green: 0.3, blue: 0.7)]),
        ("播放列表", "music.note.list", .allPlaylists, [Color(red: 0.95, green: 0.6, blue: 0.3), Color(red: 0.85, green: 0.3, blue: 0.3)]),
        ("流派", "guitars.fill", .allGenres, [Color(red: 0.3, green: 0.8, blue: 0.7), Color(red: 0.1, green: 0.5, blue: 0.5)]),
        ("文件夹", "folder.fill", .allFolders, [Color(red: 0.6, green: 0.6, blue: 0.6), Color(red: 0.35, green: 0.35, blue: 0.4)])
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Metrics.m) {
                ForEach(categories, id: \.label) { cat in
                    NavigationLink(value: cat.route) {
                        CategoryTile(label: cat.label, icon: cat.icon, gradient: cat.gradient)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Metrics.l)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("浏览")
    }
}

private struct CategoryTile: View {
    let label: String
    let icon: String
    let gradient: [Color]
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: icon)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.18))
                .offset(x: 90, y: 32)
            VStack(alignment: .leading) {
                Spacer()
                Text(label)
                    .font(.nocSection)
                    .foregroundStyle(.white)
                    .padding(Metrics.m)
            }
        }
        .aspectRatio(1.3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerCard, style: .continuous))
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 12, y: 6)
    }
}
