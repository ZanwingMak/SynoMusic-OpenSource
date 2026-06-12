import Foundation

/// 浏览导航路由：用 NavigationStack 的 value 类型驱动。
enum BrowseRoute: Hashable {
    case album(Album)
    case artist(Artist)
    case playlist(Playlist)
    case genre(Genre)
    case folder(FolderNode?)
    case allAlbums
    case allArtists
    case allPlaylists
    case allGenres
    case allFolders
}
