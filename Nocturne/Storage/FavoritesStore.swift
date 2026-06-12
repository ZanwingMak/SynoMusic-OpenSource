import Foundation

/// 喜欢的歌曲仓库：按 songID 存 UserDefaults，UI 用 @Published 驱动 SwiftUI。
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var songIDs: Set<String> = []
    @Published private(set) var snapshots: [Song] = []

    private let idsKey = "noc.favorites.ids"
    private let snapKey = "noc.favorites.snapshots"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// 是否被喜欢。
    func isFavorite(_ song: Song) -> Bool {
        songIDs.contains(song.id)
    }
    func isFavorite(_ id: String) -> Bool { songIDs.contains(id) }

    /// 切换喜欢状态。
    func toggle(_ song: Song) {
        if songIDs.contains(song.id) {
            songIDs.remove(song.id)
            snapshots.removeAll { $0.id == song.id }
        } else {
            songIDs.insert(song.id)
            // 把当前播放上下文里的歌曲信息存一份用于离线展示
            if !snapshots.contains(where: { $0.id == song.id }) {
                snapshots.append(song)
            }
        }
        persist()
    }

    /// 全量清空。
    func clear() {
        songIDs.removeAll()
        snapshots.removeAll()
        persist()
    }

    // MARK: 持久化

    private func load() {
        if let arr = defaults.stringArray(forKey: idsKey) {
            songIDs = Set(arr)
        }
        if let data = defaults.data(forKey: snapKey),
           let list = try? JSONDecoder().decode([Song].self, from: data) {
            snapshots = list
        }
    }

    private func persist() {
        defaults.set(Array(songIDs), forKey: idsKey)
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: snapKey)
        }
    }
}
