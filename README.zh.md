# SynoMusic

> 一个为群晖 NAS 打造的、漂亮的 iOS 原生音乐客户端 —— 基于 Audio Station。

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

SynoMusic 通过 DSM 的 Audio Station Web API 工作，提供干净流畅的 iOS 原生体验：浏览、搜索、播放、本地多歌单收藏、全球电台、锁屏与灵动岛全控制。

## 截图

|  资料库  |  浏览  |  设置  |
| :---: | :---: | :---: |
| ![资料库](docs/screenshots/01-library.png) | ![浏览](docs/screenshots/02-browse.png) | ![设置](docs/screenshots/03-settings.png) |

|  全屏播放器  |  服务器编辑  |
| :---: | :---: |
| ![播放器](docs/screenshots/04-player.png) | ![编辑器](docs/screenshots/05-editor.png) |

## 最新版本：1.2.9

- 进一步压缩 App 图标与预览图资源，降低安装包体积。
- 包含 1.2.8 的播放器下载、歌词、专辑封面和 QuickConnect 中继优化。
- 完整更新见 [`CHANGELOG.md`](CHANGELOG.md)。

## 功能

- **NAS 优先**：多服务器档案、Keychain 凭证、双重验证（OTP）、自签名证书信任、HTTPS / QuickConnect
- **流式播放**：AVQueuePlayer、原始流失败自动 MP3 转码兜底、AirPlay、CarPlay 远程命令
- **资料库**：专辑、艺术家、流派、文件夹、服务器歌单、*所有歌曲*（分页 + 排序）
- **本地歌单**：多个自定义收藏夹、内置「我喜欢的」、批量编辑、多选添加
- **电台**：30,000+ 全球电台（Radio-Browser API），按国家/标签/搜索
- **播放器**：全屏播放器、同步歌词、队列编辑、定时停止（预设 / 自定义 / 时间点）、点封面 ↔ 歌词切换
- **系统集成**：锁屏 Now Playing、灵动岛 Live Activity（compact / minimal / expanded）、Remote Command
- **主题**：8 种强调色 + 跟随系统 / 浅色 / 深色
- **多语言**：简体中文、繁體中文、English、日本語、한국어、Deutsch、Français
- **离线**：歌曲下载到沙盒

## 系统要求

- **iOS 17** 及更新
- 群晖 NAS，已安装 **Audio Station** 并给目标账号开启 Audio Station 权限
- 灵动岛：iPhone 14 Pro 及更新

## 从源代码构建

工程文件由 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成。

```bash
brew install xcodegen
git clone https://github.com/ZanwingMak/SynoMusic.git
cd SynoMusic
xcodegen generate
open SynoMusic.xcodeproj
```

在 Xcode 中设置你自己的开发者签名后即可运行。

## 赞助

- **PayPal** — [paypal.me/zanwing](https://paypal.me/zanwing)
- **Buy Me a Coffee** — [buymeacoffee.com/zanwing](https://buymeacoffee.com/zanwing)
- **Wise** — [wise.com/pay/me/zhenyingm1](https://wise.com/pay/me/zhenyingm1)
- **微信 / 支付宝** — 在设置 → 赞助支持中扫码

## 协议

本项目采用 **GNU GPL v3.0** 协议。详见 [`LICENSE`](LICENSE)。

> SynoMusic 是一个非官方 Audio Station 客户端。*Synology*、*DSM*、*Audio Station* 是群晖科技的商标。
