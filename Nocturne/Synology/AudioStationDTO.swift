import Foundation

// MARK: - Audio Station 接口返回的原始 DTO
// 字段命名与 Synology 返回保持一致；上层映射成 UI 模型。

struct ASListResult<Element: Decodable>: Decodable {
    let total: Int?
    let offset: Int?
    /// 不同接口返回字段不同：用动态键解析。
    let items: [Element]

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var total: Int? = nil
        var offset: Int? = nil
        var items: [Element] = []
        for key in container.allKeys {
            switch key.stringValue {
            case "total": total = try? container.decode(Int.self, forKey: key)
            case "offset": offset = try? container.decode(Int.self, forKey: key)
            default:
                if let arr = try? container.decode([Element].self, forKey: key), items.isEmpty {
                    items = arr
                }
            }
        }
        self.total = total
        self.offset = offset
        self.items = items
    }
}

// MARK: 专辑

struct ASAlbum: Decodable {
    let name: String
    let album_artist: String?
    let artist: String?
    let display_artist: String?
    let year: Int?
    let song_count: Int?
}

// MARK: 艺术家

struct ASArtist: Decodable {
    let name: String
    let album_count: Int?
}

// MARK: 流派

struct ASGenre: Decodable {
    let name: String
}

// MARK: 歌曲

struct ASSong: Decodable {
    let id: String
    let title: String
    let path: String?
    let type: String?
    let additional: ASSongAdditional?
}

struct ASSongAdditional: Decodable {
    let song_tag: ASSongTag?
    let song_audio: ASSongAudio?
    let song_rating: ASSongRating?
}

struct ASSongTag: Decodable {
    let album: String?
    let album_artist: String?
    let artist: String?
    let comment: String?
    let composer: String?
    let disc: Int?
    let genre: String?
    let track: Int?
    let year: Int?
}

struct ASSongAudio: Decodable {
    let bitrate: Int?
    let channel: Int?
    let codec: String?
    let container: String?
    let duration: Int?     // 秒
    let filesize: Int64?
    let frequency: Int?
}

struct ASSongRating: Decodable {
    let rating: Int?
}

// MARK: 播放列表

struct ASPlaylist: Decodable {
    let id: String
    let name: String
    let library: String?
    let owner: String?
    let type: String?
    let additional: ASPlaylistAdditional?
}

struct ASPlaylistAdditional: Decodable {
    let songs_total: Int?
    let songs_offset: Int?
}

// MARK: 文件夹

struct ASFolder: Decodable {
    let id: String
    let title: String
    let path: String
    let type: String       // 'folder' | 'file'
    /// 当 type == file 时携带的歌曲 ID。
    let additional: ASFolderAdditional?
}

struct ASFolderAdditional: Decodable {
    let song_id: String?
}

// MARK: 歌词

struct ASLyricsPayload: Decodable {
    let lyrics: String?
}

// MARK: 搜索

struct ASSearchHit: Decodable {
    let type: String       // 'song' / 'album' / 'artist' / 'playlist'
    let song: ASSong?
}
