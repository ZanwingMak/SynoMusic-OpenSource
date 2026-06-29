# SynoMusic

> A beautiful, native iOS music client for your Synology NAS — built on Audio Station.

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

[Official Website](https://zanwingmak.github.io/SynoMusic-OpenSource/) · [Privacy Policy](https://zanwingmak.github.io/SynoMusic-OpenSource/privacy.html) · [Terms of Use](https://zanwingmak.github.io/SynoMusic-OpenSource/terms.html) · [Latest Release](https://github.com/ZanwingMak/SynoMusic-OpenSource/releases/latest)

SynoMusic talks to the Audio Station Web API on your Synology DSM to give you a clean, fast, iOS-native music experience: browse, search, play, sync favorites and custom playlists, listen to global radio, and control everything from the Lock Screen and Dynamic Island.

## Open-source edition

This repository contains the open-source SynoMusic iOS app, including the main app target, Live Activity extension, local playlist/download storage, Synology Audio Station API client, and the GitHub Pages website.

- You bring your own Synology NAS, DSM account, and Audio Station permissions. No demo server, proxy service, or bundled credentials are included.
- The release IPA is provided for convenience; building from source requires your own Apple signing team in Xcode.
- Credentials are stored in the iOS Keychain, and downloaded songs stay inside the app sandbox.
- Screenshots and examples in this repository use anonymized sample data. Please avoid committing private NAS hosts, QuickConnect IDs, or account information.

## Screenshots

|  Library  |  Browse  |  Settings  |
| :---: | :---: | :---: |
| ![Library](docs/screenshots/01-library.png) | ![Browse](docs/screenshots/02-browse.png) | ![Settings](docs/screenshots/03-settings.png) |

|  Full Player  |  Server Editor  |
| :---: | :---: |
| ![Player](docs/screenshots/04-player.png) | ![Editor](docs/screenshots/05-editor.png) |

## Latest release: 1.3.5

- Keeps the player button state accurate when another app interrupts audio.
- Restores SynoMusic playback automatically after the external interruption ends.
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
- Xcode **26** or newer when building from source
- A Synology NAS with **Audio Station** installed and the target user granted Audio Station permission in DSM
- For Dynamic Island: iPhone 14 Pro or newer

## Build from source

The checked-in Xcode project is generated from [`project.yml`](project.yml) via [XcodeGen](https://github.com/yonaskolb/XcodeGen). Regenerate it after changing project structure, targets, build settings, or resources.

```bash
brew install xcodegen
git clone https://github.com/ZanwingMak/SynoMusic-OpenSource.git
cd SynoMusic-OpenSource
xcodegen generate
open SynoMusic.xcodeproj
```

Set your own development team in Xcode → Signing & Capabilities for both `SynoMusic` and `SynoMusicLive`, then run on a simulator or device.

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
