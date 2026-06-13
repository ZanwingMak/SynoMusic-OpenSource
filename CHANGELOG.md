# Changelog

本文档记录 Nocturne 的所有显著变更。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)；版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增（四）
- **灵动岛 + 锁屏 Live Activity**：新增 `NocturneLive` Widget Extension 实现 ActivityKit 三态：
  - **compactLeading**：曲目封面缩略图；**compactTrailing**：播放/暂停图标（playing 时 SF Symbol variable color 律动）；**minimal**：waveform/music note。
  - **expanded**：左侧 56pt 封面、中间标题+艺术家、右侧大播放图标、底部渐变进度条。
  - **锁屏**：与展开形态类似，黑色背景胶囊，跟随 NowPlaying 数据。
  - `NowPlayingActivityAttributes` 携带 `title/artist/album/isPlaying/elapsed/duration/coverURL`。主 App `Info.plist` 加 `NSSupportsLiveActivities=true`。
  - `LiveActivityCoordinator` 单例（`@unchecked Sendable` + `NSLock`）持有 Activity 句柄，规避 Swift 6 严格并发对 ActivityKit 跨 actor 边界的 sending 检查。
  - `PlaybackEngine` 在切歌 / 播放 / 暂停 / stop 时 `refreshLiveActivity()` 同步更新；timeObserver 每 0.5 s 走限流 1 s/次的 `updateLiveActivityThrottled()`。
- **歌曲评分（0-5 星）**：全屏播放器右上 Menu 下「评分」子菜单调用 `SYNO.AudioStation.Song.setrating`。
- **删除歌曲文件**：全屏播放器右上 Menu「删除文件…」走 `SYNO.FileStation.Delete`（带二次确认 alert），成功后从队列自动移除当前曲。注意：Audio Station 没有 ID3 tag 编辑 API，编辑歌曲元数据不可行——只能改评分或直接删除文件。
- **流式播放兜底**：`AVPlayerItem.failed` 且当前是 raw 直流时，自动切到 `mp3` 转码重试一次（per-song 状态，不修改用户全局音质设置），toast 提示「原始格式无法播放，正在改用 MP3 转码…」。

### 体验（四）
- **切换服务器配置立即重新登录 + 资源刷新**：SettingsView 行 tap = `setActive` + 立即停止播放 + `signOut` + 用 Keychain 密码 silent login 新档案；`RootView` 用 `.id(session.client?.profile.id)` 给 `MainShellView` 标 stable identity，账号切换时整棵子树重建，各页面的 `@State songs/albums/artists` 缓存随之丢弃下次出现重新加载。再也不需要重启 App。

### 核查
- **锁屏 NowPlaying 链路**：确认全套已就绪——`AVAudioSession(.playback, [.allowAirPlay, .allowBluetoothA2DP])` 在 `setupAudioSession()` 激活；`UIBackgroundModes: audio` 在 Info.plist；`MPNowPlayingInfoCenter` 在 `updateNowPlayingMetadata` / `updateNowPlayingPlaybackState` 每次切歌/进度/暂停都更新；`MPRemoteCommandCenter` 注册了 play/pause/togglePlayPause/next/previous/changePlaybackPosition；nonisolated artwork handler 让封面也能在系统 accessQueue 上被读取。模拟器锁屏 widget 可能不显示，实机会自动出现。

### 新增（三）
- **「所有歌曲」入口**：浏览页加入"所有歌曲" tile；`AllSongsView` 实现 200 条/页的滚动分页加载（接近末 30 条触发下一页）、4 种排序（名称/艺术家/专辑/最近添加）；行内 swipe action：「接下来」「喜欢/取消喜欢」「加入歌单」；contextMenu 同样齐备；顶部「播放/随机」整库按钮。
- **本地歌单（多收藏夹）**：新增 `PlaylistStore` 管理多个本地歌单，「我喜欢的」改为内置歌单（固定 UUID，不可删除/重命名，但可清空）；其它歌单用户可自建/重命名/删除。
  - 浏览页加「我的歌单」入口 → `LocalPlaylistsView` 列表 + 新建弹窗（名称 + 8 色封面色板）
  - 任意歌曲 contextMenu / swipe →「添加到歌单…」打开 `AddToPlaylistSheet` 多选 + 顶部「新建歌单…」内嵌新建
  - 全屏播放器右上多了一个 ＋ 按钮（旁边是心形），快速加入歌单
  - 自动迁移旧 `FavoritesStore` 的 UserDefaults 数据（`noc.favorites.ids` + `noc.favorites.snapshots`）到内置「我喜欢的」歌单后清除老 key
  - `LocalPlaylistDetailView` 复用为「我喜欢的」与所有用户自建歌单详情：播放/随机、批量编辑、清空、重命名、删除
  - 旧 `FavoritesView.swift` 删除；旧文件名 `FavoritesStore` 通过 `typealias` 暂时桥接 EnvironmentObject 调用方

### 体验（三）
- **mini 播放器进度条溢出修复**：旧版用 `ProgressView(.linear)` overlay 在 GlassPanel 之外，两端圆头超出胶囊圆角。改为 GeometryReader + Rectangle 自绘进度条嵌入 GlassPanel 内部底端，由 GlassPanel 的 `clipShape` 自动裁切，不再溢出；底色用 `Color.primary.opacity(0.10)`，进度色用 `Theme.accentGradient`。

### 新增
- **喜欢功能**：`FavoritesStore`（UserDefaults + 离线 Song 快照），全屏播放器右上角心形按钮按下变填充 + 弹性放大动画；浏览页/资料库首页新增「我喜欢的」入口，可全播/随机播。
- **全球电台**：基于 radio-browser.info 公开 API，浏览页加「电台」分类。支持热门 / 12 个常用国家 / 10 个常用流派 pill 切换 + 关键词搜索；点击直接通过 `AVPlayer` 播放 stream。PlaybackEngine 现可识别 `song.id` 以 `radio:` 开头并走 `song.path` 直流，与 Audio Station 队列分流，不污染本地播放队列。
- **定时停止**：播放器底部新增月亮按钮，弹出 `SleepTimerSheet`。支持 5/10/15/30/45/60/90 分钟倒计时与「本曲结束后停止」。激活时月亮图标变 accent 色 + 绿点角标。倒计时归零 / 曲终自动 `pause` 并 toast。
- **随机歌单**：资料库首页新增渐变 ActionCard「随机歌单」，从全库通过 `SYNO.AudioStation.Song.list?sort_by=random` 抓 100 首；DSM 不支持 random 排序时客户端拉大 limit 后 `shuffled()` 兜底。

### 体验
- 文件夹里的单曲行整行可点击（`.contentShape(Rectangle())`）；按压时整行 0.98 缩放 + accent 浅色填充 + 触感反馈，不再只有文字才响应。
- 迷你播放器改用 `.safeAreaInset(.bottom)` 实现，让 TabView 内所有滚动视图自动让出空间。移除各页面手工塞的 `Color.clear.frame(height: 100)` 底部占位。底部信息不再被悬浮播放条遮住。

### AirPlay 验证
- 已检查：`AVAudioSession.setCategory(.playback, options: [.allowAirPlay, .allowBluetoothA2DP])`、`Info.plist UIBackgroundModes: audio`、`AVRoutePickerView` 已嵌入全屏播放器、`MPRemoteCommandCenter` 注册了 play/pause/next/prev/seek。模拟器无法路由到真实 AirPlay 接收器（系统限制），实机上点击 AirPlay 按钮会弹出系统路由选择器，可选 HomePod / Apple TV / 其它 AirPlay 接收方。

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
- 设置页服务器管理改为「收货地址」风格：行 tap 设为默认 + ✓ 标记 + 行内 ⓘ 编辑 + 左滑删除（带确认 Alert）；删除当前已登录档案会先退出登录。移除原"切换到 xxx"按钮形式。
- 备注名为空的档案在列表中回退显示主机，避免出现空白行。
- 服务器行额外显示「已登录」绿色徽章，区分"当前会话"与"默认登录档案"两层概念。
- App 启动若有默认档案 + Keychain 密码，自动后台静默登录；失败回退到 LoginFlowView 并通过顶部 toast 提示原因。
- 全局顶部 toast：承载播放/连接状态消息，可点关闭。FullPlayerView 内置独立 overlay 避免被 sheet 遮挡。
- 播放器在未连接服务器时进入 Demo 模拟：UI 时间线照走，封面/进度/歌词/Now Playing 都正常，仅不发声，并以 toast 持续提示原因。
- AVPlayerItem 失败（403/网络中断等）转成可见 toast：「播放中断：…」。

### 修复
- 「添加服务器」打开编辑器时，密码字段强制清空，避免被 SwiftUI 状态复用或系统密码自动填充残留。SecureField 显式标注 `.textContentType(.password)`。
- DEBUG `-autoconnect` 启动参数改为整个进程只触发一次，防止之后每次重开编辑器都自动尝试连接。
- 「连接并保存」按钮的 loading 圈不再贴最左：与「正在连接...」文本一起在按钮中央居中显示。
- 「连接并保存」失败也持久化基础配置：进入流程第一步立即 `upsert(p)`，登录成功后再追加 `setActive` / `savePassword` / `signIn`。这样即便密码错、网络断、402 权限不足，新增的服务器条目也会立即出现在「设置 → 服务器」列表里，可后续编辑重试，不再"什么都没留下"。错误 Alert 会明确告知"配置已保存到列表"。
- **首页点击专辑/艺术家无反应**：只有「浏览」Tab 的 `NavigationStack` 注册了 `BrowseRoute` 的 `navigationDestination`，其它 Tab（资料库 / 搜索）里同名 `NavigationLink(value:)` 因此全部静默失败。现把 destination 集中到 `BrowseRoute.destination`，并以 `View.browseRoutes()` modifier 在每个 Tab 的 NavigationStack 上 attach 一次。资料库 / 浏览 / 搜索 三 Tab 现在都能从专辑卡片正确进入专辑详情。
- 点歌后无反馈：`playback.play(queue:startAt:)` 立刻设置 "正在加载：{歌名}" toast；监听 `AVPlayerItem.status`，`.readyToPlay` 时清除 toast、`.failed` 时把 `item.error.localizedDescription` 写到 toast 让用户看到原因（HTTPS 证书、流不可达、权限等）。
- **点专辑播放按钮闪退（SIGTRAP）**：根因是 `item.observe(\.status)` 的 KVO 闭包在非主线程触发时访问 `@MainActor` 的 `PlaybackEngine`，被 Swift 6 严格并发的 `swift_task_checkIsolated` 主动 trap。改用 Combine：`item.publisher(for: \.status).receive(on: DispatchQueue.main).sink`，回调强制在 main 上，并把 `[weak self, weak item]` 同时弱捕获，杜绝隔离违规。
- 同步修了其它三处隐患：`addPeriodicTimeObserver`、`player.seek(to:)` 完成回调、`updateNowPlayingMetadata` 内的封面下载 Task — 全部改为显式 `Task { @MainActor in ... }` 跳板。`BrowseRoute.destination` 标注 `@MainActor`。
- **浏览 → 文件夹 → 文件点了没反应**：`folder.cgi` 在不同 DSM 版本上对 `type=file` 节点要么把 `song_id` 放 `additional` 里，要么直接拿 `id` 当 song id。`playFile` 改成 `node.songID ?? node.id` 兜底，并在 songID 为空时显式 toast 提示，不再静默吞掉点击。

### 测试
- 新增 `AlbumPlaySmokeTest.test_fullPlayerLaunchDoesNotCrash`：launch `-demo -fullplayer` 验证 KVO/timeObserver 转 2 秒后进程仍处于 `runningForeground`，回归测试上面那次 KVO 闪退。
- 新增 `AlbumPlaySmokeTest.test_nowPlayingArtworkHandlerSurvivesBackgrounding`：launch 后按 Home 入后台再回到前台，强制 MediaPlayer 在自己的 accessQueue 上回调 artwork handler；断言进程仍未崩溃。回归测试本次 attachArtwork SIGTRAP。

### 新增（二）
- **定时停止扩展**：SleepTimerSheet 在 7 个分钟预设之外，增加「自定义时长」（小时 0-23 + 分钟 0-59 双 wheel 选择）与「时间点停止」（DatePicker 选今天/明天任一时间点，自动转换为倒计时）。
- **喜欢列表批量编辑**：FavoritesView 右上菜单进入「批量编辑」模式；行内圆圈选中；底部浮条提供「全选/全不选」「播放选中」「删除选中」；与 FavoritesStore.remove(ids:) 联动。
- **App 图标**：1024×1024 渐变（粉→紫）+ 白色 5 条波形 SF 风格 icon，通过一次性 Swift 脚本用 NSGraphicsContext 生成；放入 `Assets.xcassets/AppIcon.appiconset/AppIcon.png`，更新 Contents.json filename。

### 体验（二）
- 迷你播放器布局再修：上一版 `.safeAreaInset(.bottom)` 放在 TabView 上导致 mini player 被 TabBar 覆盖、内容也被遮挡。改为 ZStack 浮 + `View.reserveMiniPlayer(visible:)` modifier，让每个 NavigationStack 内部用 safeAreaInset reserve `miniPlayerHeight + 8` 空间，mini player 干净悬浮在 TabBar 之上。
- 电台切换分类：tap pill 立即清空 stations + 进入 LoadingState，避免"切了但旧列表还在"的错觉。
- 「重试」按钮：点击触发 360° 旋转 + 0.9 缩放弹簧动效，再延迟 0.18s 执行 retry callback，反馈用户操作已收到。

### 修复（三）
- 设置中新增配置后列表不刷新：根因是 `simctl terminate` 或 SwiftUI @Published 时序导致更新未到。`ServerStore.save()` 末尾显式 `defaults.synchronize()` 保证 UserDefaults 同步落盘；`upsert` 进入时显式 `objectWillChange.send()` 作为 SwiftUI 双保险。重启后默认服务器 + Keychain 密码静默登录验证通过。

### 修复（再）
- **MPMediaItemArtwork handler 闭包隔离崩溃（SIGTRAP）**：上次 `updateNowPlayingMetadata` 内的 `MPMediaItemArtwork(boundsSize:) { _ in image }` 写在 `@MainActor Task` 里，闭包继承了 main actor 隔离；MediaPlayer 内部在它自己的 `*/accessQueue` 上调用这个闭包时 Swift 6 runtime 主动 `_swift_task_checkIsolated` SIGTRAP。改为 `nonisolated private static func attachArtwork(_:)` 静态方法在 nonisolated 上下文构造 artwork 并合并进 `MPNowPlayingInfoCenter`，handler 闭包不再绑定到 MainActor。

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
