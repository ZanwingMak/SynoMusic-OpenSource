# SynoMusic

> A beautiful, native iOS music client for your Synology NAS — built on Audio Station.

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

SynoMusic talks to the Audio Station Web API on your Synology DSM to give you a clean, fast, iOS-native music experience: browse, search, play, sync favorites and custom playlists, listen to global radio, and control everything from the Lock Screen and Dynamic Island.

## Screenshots

|  Library  |  Browse  |  Settings  |
| :---: | :---: | :---: |
| ![Library](docs/screenshots/01-library.png) | ![Browse](docs/screenshots/02-browse.png) | ![Settings](docs/screenshots/03-settings.png) |

|  Full Player  |  Server Editor  |
| :---: | :---: |
| ![Player](docs/screenshots/04-player.png) | ![Editor](docs/screenshots/05-editor.png) |

## Latest release: 1.3.0

- Adds online lyrics lookup when Audio Station has no embedded lyrics.
- Fixes QuickConnect portal selection and restores the album detail cover to the fixed square layout.
- See [`CHANGELOG.md`](CHANGELOG.md) for the full release notes.

## Features

- **NAS first**: Multi-server profiles with Keychain credentials, 2FA (OTP), self-signed certificate trust, HTTPS/QuickConnect
- **Streaming**: AVQueuePlayer, automatic raw → MP3 transcode fallback when a format is unsupported, AirPlay, CarPlay-compatible Remote Command Center
- **Library**: Albums, Artists, Genres, Folders, Server playlists, *All Songs* with paginated load and sort
- **Local playlists**: Multiple custom playlists, "Favorites" as a pinned built-in, batch edit, multi-add via sheet
- **Radio**: 30,000+ stations via the public Radio-Browser API, by country / tag / search
- **Player**: Full-screen player with live lyrics, queue editing, sleep timer (presets, custom, time-of-day), tap cover ↔ lyrics
- **System integration**: Lock Screen Now Playing, Dynamic Island Live Activity (compact, minimal, expanded), MPRemoteCommand
- **Theming**: 8 accent color palettes + system / light / dark appearance
- **Languages**: Simplified Chinese, Traditional Chinese, English, Japanese, Korean, German, French
- **Offline**: Per-song downloads stored in the app sandbox

## Requirements

- iPhone running **iOS 17 or later**
- A Synology NAS with **Audio Station** installed and the target user granted Audio Station permission in DSM
- For Dynamic Island: iPhone 14 Pro or newer

## Build from source

This project is generated via [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/ZanwingMak/SynoMusic.git
cd SynoMusic
xcodegen generate
open SynoMusic.xcodeproj
```

Set your own development team in Xcode → Signing & Capabilities, then run on a simulator or device.

## Project layout

```
SynoMusic/
├── App/                 # @main entry + RootView
├── Audio/               # PlaybackEngine, NowPlaying, Live Activity bridge
├── DesignSystem/        # Theme, ThemeManager, L10n, Typography, Components
├── Features/
│   ├── Browse/          # Albums / Artists / Genres / Folders / All Songs
│   ├── Favorites/       # Local playlists incl. built-in Favorites
│   ├── Library/         # Home with shortcut cards
│   ├── Login/           # Server editor + login flow
│   ├── Player/          # MiniPlayerBar, FullPlayerView, SleepTimerSheet
│   ├── Radio/           # RadioAPI + RadioBrowseView
│   ├── Search/          # Debounced search
│   └── Settings/        # Servers, theme, language, sponsor, about
├── Models/              # Song / Album / Artist / Playlist / ServerProfile …
├── Storage/             # ServerStore, PlaylistStore, KeychainStore, DownloadManager
├── Synology/            # SynologyClient, AudioStationAPI, DTOs, errors
└── SynoMusicLive/       # Widget extension: Live Activity + Lock Screen
```

## Sponsor

If SynoMusic saves you a Spotify subscription, consider supporting development.

- **PayPal** — [paypal.me/zanwing](https://paypal.me/zanwing)
- **Buy Me a Coffee** — [buymeacoffee.com/zanwing](https://buymeacoffee.com/zanwing)
- **Wise** — [wise.com/pay/me/zhenyingm1](https://wise.com/pay/me/zhenyingm1)
- **WeChat / Alipay** — open Settings → Sponsor for QR codes

## License

This project is licensed under the **GNU General Public License v3.0**. See [`LICENSE`](LICENSE).

> SynoMusic is an unofficial Audio Station client. *Synology*, *DSM*, and *Audio Station* are trademarks of Synology Inc.
