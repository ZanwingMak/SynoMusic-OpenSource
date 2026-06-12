# Changelog

本文档记录 Nocturne 的所有显著变更。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)；版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.0] - 2026-06-12

首个公开版本。

### 新增

- **群晖连接**
  - 多服务器档案管理；支持 HTTP/HTTPS，HTTPS 可信任自签名证书
  - SYNO.API.Auth Login/Logout，支持二步验证（OTP）
  - Keychain 凭证存储
- **Audio Station API 客户端**
  - 专辑/艺术家/流派/文件夹/播放列表/歌曲列表与详情
  - 歌曲与专辑封面 URL 构造
  - 流式与转码 URL（`raw` / 320 / 128）
  - LRC 歌词获取与解析
  - 搜索歌曲
- **播放引擎（AVQueuePlayer）**
  - 队列管理：追加、移除、移动、随机播放
  - 重复模式：关闭 / 全部 / 单曲
  - 后台播放、`AVAudioSession` 配置、AirPlay
  - 锁屏 Now Playing、远程命令（播放/暂停/上一首/下一首/进度跳转）
  - 缓冲状态与失速感知
- **界面**
  - SwiftUI + SF Pro Rounded 的设计系统：Theme、Typography、Haptics、Liquid Glass 面板、按钮样式、加载/空态/错误态
  - 登录流程：动态光晕背景、服务器列表、Glass 表单
  - 资料库首页：时段问候、最近添加横向滑动、全部专辑网格、艺术家圆头像
  - 浏览：五品类大卡入口 + 各品类全部视图与详情
  - 搜索：300 ms 防抖 + 搜索历史
  - 迷你播放器：浮于 TabBar 之上，进度条贴底
  - 全屏播放器：封面英雄区、波形进度、动态背景光斑、AirPlay、循环/随机、歌词面板（同步高亮、自动滚动）、队列编辑
  - 设置：服务器切换、音质、下载管理、关于
- **离线下载**
  - 沙盒下载、本地索引、空间占用统计、单首/批量删除
- **测试**
  - 13 个单元测试：SynologyError 错误码、LRC 解析、播放队列、ServerProfile

### 工程

- XcodeGen `project.yml` 驱动；仓库不含 `.xcodeproj`
- Swift 6 严格并发：`SynologyClient` / `AudioStationAPI` 标记 `@unchecked Sendable` 并加锁保护 `sid`
- iOS 17.0 起；以 Xcode 26 / Swift 6.3 通过编译

[Unreleased]: https://github.com/ZanwingMak/Nocturne/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ZanwingMak/Nocturne/releases/tag/v1.0.0
