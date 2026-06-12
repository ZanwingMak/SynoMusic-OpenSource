# Nocturne

> 你的群晖音乐，私人夜曲。

Nocturne 是一个面向群晖 NAS 用户的 iOS 原生音乐播放器。它通过 Audio Station 的 Web API 连接你的 DSM，把 NAS 上的音乐库变成一个流畅、好看、原生的 iPhone 体验：浏览专辑/艺术家/流派/文件夹/播放列表、实时搜索、全屏播放器（含同步歌词与 AirPlay）、后台播放与锁屏控制、离线下载。

本项目是非官方客户端。Synology、DSM、Audio Station 商标归群晖科技所有。

---

## 截图位置

| 场景 | 说明 |
|------|------|
| 登录 | 暗色渐变 + 浮动光晕背景；服务器列表 + Glass 卡片表单 |
| 首页 | 时段问候 + 最近添加专辑横向滑动 + 全部专辑网格 + 艺术家圆头像 |
| 浏览 | 五张品类大卡（专辑/艺术家/播放列表/流派/文件夹）|
| 全屏播放 | 封面英雄区、波形进度、AirPlay、循环/随机、歌词面板、队列编辑 |
| 设置 | 服务器切换、音质、下载管理、关于 |

## 功能

- **连接管理**：多服务器档案、HTTPS（含自签名信任）、QuickConnect ID、用户名/密码 + OTP（二步验证）登录、Keychain 凭证存储
- **资料库浏览**：专辑、艺术家、流派、文件夹、播放列表（含智能列表）
- **搜索**：300ms 防抖实时搜索 + 搜索历史
- **播放引擎**：基于 `AVQueuePlayer`，支持后台播放、AirPlay、CarPlay 远程命令、锁屏 Now Playing、跨歌曲缓冲、播放队列重排
- **歌词**：拉取 Audio Station 的 LRC 并解析为时间轴；播放时按当前进度高亮居中
- **音质选择**：原始（FLAC/WAV/MP3 不转码）、高质 320 kbps、标准 128 kbps
- **离线下载**：把歌曲下载到沙盒，离线优先播放，统一空间管理
- **设计系统**：SF Pro Rounded 字体、`.ultraThinMaterial` Liquid Glass、自定义 ButtonStyle、Haptics、Light/Dark 自适应
- **可访问性**：Dynamic Type、VoiceOver 标签、Reduce Motion 兼容

## 技术栈

| 层 | 选型 |
|----|------|
| 框架 | SwiftUI（iOS 17+）|
| 语言 | Swift 6.0（严格并发开启）|
| 状态管理 | `ObservableObject` + `EnvironmentObject` |
| 音频 | `AVQueuePlayer` + `AVAudioSession` + `MediaPlayer.MPNowPlayingInfoCenter` |
| 网络 | `URLSession` + `async/await` |
| 存储 | `UserDefaults`（档案/索引）+ `Security.framework` Keychain（密码）|
| 项目生成 | [XcodeGen](https://github.com/yonki-lin/XcodeGen) + `project.yml`（仓库不含 `.xcodeproj`）|

## 目录

```
Nocturne/
├── project.yml                    # XcodeGen 配置
├── README.md / CHANGELOG.md
└── Nocturne/
    ├── App/                       # 入口与根视图
    ├── DesignSystem/              # 主题、字体、组件、Haptics
    ├── Models/                    # Song/Album/Artist/Playlist/FolderNode/ServerProfile
    ├── Synology/                  # Client、Auth、AudioStationAPI、DTO、Error
    ├── Audio/                     # PlaybackEngine（队列/Now Playing/远程命令）
    ├── Storage/                   # ServerStore、KeychainStore、DownloadManager、AppSession
    ├── Features/
    │   ├── Login/                 # 服务器列表、编辑、登录
    │   ├── Library/                # 首页与 ViewModel
    │   ├── Browse/                 # 入口 + 全部专辑/艺术家/播放列表/流派/文件夹/详情
    │   ├── Search/                 # 实时搜索 + 历史
    │   ├── Player/                 # 迷你播放器 + 全屏播放器
    │   └── Settings/               # 设置与下载管理
    └── Resources/                  # Info.plist、Assets.xcassets
```

## 运行

### 依赖
- macOS + Xcode 16+（建议 26）
- Homebrew + XcodeGen

```bash
brew install xcodegen
```

### 生成与编译

```bash
cd Nocturne
xcodegen generate                 # 生成 Nocturne.xcodeproj
open Nocturne.xcodeproj           # 打开 Xcode
# 或命令行编译
xcodebuild -project Nocturne.xcodeproj -scheme Nocturne \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' build
```

### 运行单元测试

```bash
xcodebuild test -project Nocturne.xcodeproj -scheme Nocturne \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -only-testing:NocturneTests
```

当前 13 个单测全绿，覆盖：
- Synology 错误码映射
- LRC 歌词解析（含 `[mm:ss.xx]` / `[mm:ss]` / 多时间戳）
- 播放队列基本操作（追加、移除、重复模式循环）
- ServerProfile URL/默认值

## 群晖连接说明

1. 在 DSM 套件中心安装并启动 **Audio Station**
2. 在 Nocturne 中添加服务器：
   - 备注名：任意
   - 协议：`http`（局域网常用 5000） 或 `https`（外网建议 5001）
   - 主机：内网 IP / DDNS / QuickConnect ID
   - 端口：默认 5000 / 5001
   - 用户名：DSM 账号
3. 输入密码登录；启用了二步验证时，在 OTP 字段填入 6 位代码

> 局域网 HTTP 已在 `Info.plist` 中放行（`NSAllowsArbitraryLoads` + `NSAllowsLocalNetworking`），可直连本地 NAS。

## CHANGELOG 维护约定

- 每次合并新功能或修复必须更新 `CHANGELOG.md`
- 遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 与 [SemVer](https://semver.org/lang/zh-CN/)
- 把变更写在 `[Unreleased]` 区段，发版时再切到对应版本号

## License

MIT
