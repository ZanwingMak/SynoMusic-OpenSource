# Changelog

本文档记录 Nocturne 的所有显著变更。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)；版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增
- DEBUG-only 演示模式：`-demo` 启动参数跳过登录并注入样本专辑/艺术家/歌曲；`-tab=browse|search|settings` 设定初始 Tab；`-fullplayer` 直接弹出全屏播放器；`-editor` 弹出服务器编辑器。便于设计审查与模拟器截图，不影响 Release。
- 服务器编辑器内置密码 / OTP 字段与"连接并保存"按钮，一步完成档案创建 + 真实 SYNO.API.Auth Login。
- 端口字段改为数字键盘 TextField，支持任意 1-65535；切换 HTTP/HTTPS 时若仍为默认端口才自动跟随。
- 登录列表新增长按菜单（编辑 / 用其他密码登录 / 移除）。
- 点击已保存档案时，若 Keychain 中已存密码则自动登录（显示行内 ProgressView），失败再回退至 LoginView。

### 变更
- `ServerEditorView` 接管原 `LoginView` 的"输入密码 → 登录"流程；`LoginView` 仅在需要更换密码时使用。
- HTTP/HTTPS 切换会基于"是否仍为默认端口"判定是否自动同步端口，避免覆盖用户自定义值。

### 修复
- DSM 7+ 兼容：`SYNO.API.Auth` 的请求路径从 `auth.cgi` 切到 `entry.cgi`（DSM 6/7 通用），适配 DSM 7+ 老路径退役。
- 错误码 402 的中文文案改为可执行提示：「账号未授权访问 Audio Station。请在 DSM 控制面板 → 用户与群组 → 编辑该用户 → 应用程序 中允许 Audio Station，再重试。」此前误显示为模糊的「权限不足」，并易被误解为密码错误。
- 内部判断"是否走认证错误码表"改为读 query 中 `api=SYNO.API.Auth`，而不是 hardcoded 的 path 前缀，使路径变更不影响错误码翻译。

### DEBUG 工具
- 服务器编辑器 `-host / -port / -user / -password / -https / -autoconnect` 启动参数：用于在没有键盘输入能力的模拟器里端到端打通真实 NAS 请求，仅用于本地诊断。

### 体验
- 服务器编辑器布局重排：协议/主机/端口/用户名/密码 + 「连接并保存」按钮全部压进第一屏，无需滚动。
- 备注名、二步验证码（OTP）、记住密码、信任自签名证书、仅保存配置 折叠进默认收起的「高级」 DisclosureGroup。
- 错误从行内红字改为 `.alert` 弹窗，承载多按钮：「我知道了」+ 针对 402 提供「复制 DSM 路径」直接把指引塞进剪贴板。
- 触发 403（OTP）时自动展开「高级」并把焦点引导文案塞进 Alert。

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
