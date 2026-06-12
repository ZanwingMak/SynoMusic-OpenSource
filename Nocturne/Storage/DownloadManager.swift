import Foundation

/// 下载条目状态。
enum DownloadStatus: String, Codable { case pending, downloading, completed, failed }

/// 已下载/正在下载的歌曲条目。
struct DownloadedSong: Identifiable, Codable, Hashable {
    let id: String           // = Song.id
    var title: String
    var artist: String?
    var album: String?
    var fileURLPath: String  // 沙盒相对路径
    var size: Int64
    var status: DownloadStatus
    var addedAt: Date
}

/// 离线下载管理器：把流 URL 下载到沙盒 Documents/Downloads/{songID}.{ext}。
@MainActor
final class DownloadManager: ObservableObject {
    @Published private(set) var entries: [DownloadedSong] = []
    @Published var allowCellularDownload: Bool = false

    private let fileManager = FileManager.default
    private let indexKey = "noc.downloads.index"

    init() { load() }

    /// 下载目录的绝对 URL。
    var downloadsDir: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 已下载歌曲对应的本地文件 URL；若没下完返回 nil。
    func localURL(for songID: String) -> URL? {
        guard let entry = entries.first(where: { $0.id == songID && $0.status == .completed }) else { return nil }
        let url = downloadsDir.appendingPathComponent(entry.fileURLPath)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// 下载一首歌（按 streamURL 抓字节，保存到本地）。
    func download(song: Song, streamURL: URL) async {
        let ext = (song.codec ?? "mp3").lowercased()
        let filename = "\(song.id).\(ext)"
        let dest = downloadsDir.appendingPathComponent(filename)

        var entry = DownloadedSong(
            id: song.id,
            title: song.title,
            artist: song.artist,
            album: song.album,
            fileURLPath: filename,
            size: 0,
            status: .downloading,
            addedAt: Date()
        )
        upsert(entry)

        do {
            let (data, _) = try await URLSession.shared.data(from: streamURL)
            try data.write(to: dest, options: .atomic)
            entry.size = Int64(data.count)
            entry.status = .completed
            upsert(entry)
        } catch {
            entry.status = .failed
            upsert(entry)
        }
    }

    /// 删除一项。
    func remove(songID: String) {
        if let entry = entries.first(where: { $0.id == songID }) {
            let url = downloadsDir.appendingPathComponent(entry.fileURLPath)
            try? fileManager.removeItem(at: url)
        }
        entries.removeAll { $0.id == songID }
        save()
    }

    /// 清空所有下载。
    func clearAll() {
        for e in entries {
            try? fileManager.removeItem(at: downloadsDir.appendingPathComponent(e.fileURLPath))
        }
        entries = []
        save()
    }

    /// 已用空间（字节）。
    var totalBytes: Int64 {
        entries.filter { $0.status == .completed }.reduce(0) { $0 + $1.size }
    }

    // MARK: 持久化

    private func upsert(_ entry: DownloadedSong) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        } else {
            entries.append(entry)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: indexKey) else { return }
        if let list = try? JSONDecoder().decode([DownloadedSong].self, from: data) {
            self.entries = list
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: indexKey)
        }
    }
}

/// 字节数 → 可读字符串。
extension Int64 {
    var humanSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}
