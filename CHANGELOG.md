# Changelog

本文档记录 SynoMusic 的所有显著变更。
格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)；版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.3.4] - 2026-06-18

### 修复
- 修复从设置页点击未保存密码的服务器并完成登录后，登录页不会自动关闭回到设置页的问题。

### 版本
- 发布版本号更新为 `1.3.4`。

## [1.3.3] - 2026-06-18

### 变更
- 播放页「歌词编辑」入口移入右上角更多菜单，并补齐多语言文案。
- 重做歌词设置面板布局，避免重复标签和空白行，字号与延迟调整更紧凑。
- 浏览页主页和二级页面为迷你播放器预留底部空间，避免列表内容被遮挡。

### 版本
- 发布版本号更新为 `1.3.3`。

## [1.3.2] - 2026-06-18

### 变更
- 播放页歌词设置入口移到歌曲标题区域左上方，颜色与播放器其它操作图标保持一致。
- 歌词设置支持实时预览字号、滚动与延迟，只有点击保存后才写入偏好设置。
- QuickConnect 登录优先使用群晖中继接口返回的 HTTPS 设备地址，并复用最近一次可用地址。

### 修复
- 修复 QuickConnect 外网登录在部分网络下长时间停留 connecting 的问题。
- 修复缺少已保存密码时只提示不跳转登录页的问题。
- 修复浏览文件夹列表滚动被行按压手势拦截的问题，并避免二级页面底部被迷你播放器遮挡。

### 版本
- 发布版本号更新为 `1.3.2`。

## [1.3.1] - 2026-06-18

### 新增
- 设置页 QuickConnect 当前会话显示已解析设备地址，并提供「更新设备地址」手动刷新入口。
- 播放页歌词支持调整字号、是否跟随进度滚动和时间延迟。

### 变更
- QuickConnect 编辑页固定使用 HTTPS 通道，已通过 QuickConnect 登录的服务器不再允许切回直连模式。
- 切换服务器账号时保留当前页面并显示行内 loading，登录成功后再替换会话。
- 播放页顶部副标题改为播放来源：专辑、歌单、随机100首、所有歌曲等上下文。
- 播放页进度条改为松手后再 seek，降低拖动卡顿。
- 原始格式播放失败自动回退 MP3 时不再弹出顶部提示，改为更新当前实际音质徽标。
- 播放专辑或歌单时不再弹出「正在加载」顶部提示。

### 修复
- 修复 QuickConnect 外网中继登录与本地表单状态不一致的问题。
- 修复服务器编辑页连接进度 Toast 显示在 sheet 背后的问题。
- 提高暗色登录页输入提示文字对比度。
- 限制专辑详情页顶部封面高度，避免竖版封面挤压标题与作者信息。

### 版本
- 发布版本号更新为 `1.3.1`。

## [1.3.0] - 2026-06-17

### 新增
- 播放页歌词支持在线获取：Audio Station 没有歌词时，会自动从 LRCLIB 查询同步歌词或纯文本歌词。

### 变更
- 专辑详情页封面恢复为固定方形封面，移除点击展开/收起交互。

### 修复
- 修复 QuickConnect 登录会错误沿用用户选择的 HTTP/HTTPS 通道，导致连到不可用端口的问题。
- 优化 QuickConnect 候选地址顺序，优先使用实际可登录的 DDNS / 公网 IP，降低 direct quickconnect 域名不可达导致的失败概率。

### 版本
- 发布版本号更新为 `1.3.0`。

## [1.2.9] - 2026-06-17

### 变更
- 进一步压缩 App 图标与预览图资源，降低安装包体积。

### 版本
- 发布版本号更新为 `1.2.9`。

## [1.2.8] - 2026-06-17

### 新增
- 播放页底部新增下载按钮，区分未下载、下载中、已下载状态，并可直达下载管理。
- 播放页右上菜单新增「下载管理」，可从播放器直接跳转到设置里的下载列表。
- 专辑详情页封面支持点击展开/收起，竖版封面默认完整显示，避免遮挡专辑名和作者。

### 变更
- 调整播放页右上菜单位置、宽度与入场动画，使弹窗更靠近三点入口。
- 下载开始提示改为短暂显示，下载完成后再提示结果，不再长时间停留。
- 歌词面板支持点击歌词行跳转播放进度，并优化当前歌词行高亮和自动滚动。

### 修复
- 修复 QuickConnect 在复杂网络下未优先使用 `relay_dn` / `relay_ip` / `relay_port` 中继候选地址的问题。

### 版本
- 发布版本号更新为 `1.2.8`。

## [1.2.7] - 2026-06-17

### 变更
- 默认图标与商店图标改为非二次元播放器风格，继续保留 `1024x1024` 源图。
- 10 张二次元图标改为用户可切换的备用图标，仅保留 `120x120 @2x` 与 `180x180 @3x`，并统一设置页预览图为 `180x180`。
- 规范化 App 图标资源命名与 `Contents.json`，压缩图标资源体积。

### 修复
- 修复模拟器安装脚本可能选中旧 DerivedData 构建产物的问题，确保安装当前构建出来的 App。

### 版本
- 发布版本号更新为 `1.2.7`。

## [1.2.6] - 2026-06-17

### 新增
- 播放页右上菜单新增「下载歌曲 / 重新下载 / 删除下载」，下载内容进入设置页下载管理，并在播放时优先使用本地缓存。
- 设置页下载管理改为共享全局下载状态，可查看下载中、已下载与下载失败条目。

### 修复
- 修复播放页右上菜单无法通过点击外部关闭的问题，菜单关闭层改为覆盖整个播放页。
- 修复复制歌曲标题或作者时复用全局播放状态 toast 导致弹窗闪烁的问题，改为播放页内的独立轻提示。
- 修复切换 App 图标后的应用内提示未补齐多语言的问题；系统自带确认弹窗仍由 iOS 控制。
- 修复 App 图标资源边缘带白线的问题，重新裁切主图标、候选图标与设置页预览图。
- 增强 QuickConnect 登录：登录时会按解析出的 `pingpong_desc`、`smartdns`、DDNS、公网 IP 等候选地址逐个尝试。

### 版本
- 发布版本号更新为 `1.2.6`。

## [1.2.4] - 2026-06-16

### 新增
- 新增 10 个自行生成的二次元耳机音乐主题 App 图标，并可在设置里自由切换。
- 浏览页新增「历史记录」，可查看最近播放歌曲与被替换前的播放队列，并可恢复历史队列。
- 首次开始播放且未显示迷你播放器时，自动弹出全屏播放页。
- 播放页新增当前音质显示，歌曲名和作者支持复制。

### 变更
- 播放页右上更多菜单改为 iOS 26 液态玻璃风格，优化圆角、点击反馈、评分星标空心/实心状态，并避免播放背景下闪烁。
- 设置里的锁屏控制和 AirPlay 改为始终开启，避免系统播放路由与锁屏卡片状态不一致。
- 随机入口只随机生成 100 首播放队列，不再改变播放器当前随机播放开关状态。

### 修复
- 修复 QuickConnect ID 登录：支持 QuickConnect 区域站点跳转、数组/对象返回结构、`smartdns` 与 `pingpong_desc` 候选地址。
- 修复评分、删除文件请求服务器后没有实际效果的问题；删除文件改用 File Station Delete 的 `start` 方法。
- 修复加入队列可重复加入同一首歌的问题，并增加重复提示。
- 修复首页下拉刷新取消请求时显示「加载失败，请求已取消」的问题。
- 修复开启随机播放后，在「所有歌曲」点播指定歌曲可能没有播放对应歌曲的问题。
- 修复空成功响应的 API 解析，避免服务器返回成功但无 `data` 时被误判失败。

### 版本
- 发布版本号更新为 `1.2.4`。

## [1.2.3] - 2026-06-16

### 修复
- 修复设置里切换强调色后 Tab、播放器、队列、定时停止、AirPlay 激活色等界面需要重启才完全生效的问题。
- 修复专辑/歌曲列表点播时顶部「正在加载」提示过快消失且未翻译的问题；加载提示现在至少可见一小段时间。
- 修复随机播放开启时，在「所有歌曲」里点某一首可能播放到随机队列中另一首的问题。
- 修复本地「我的歌单」里内置「我喜欢的」不随当前语言翻译的问题。
- 修复全屏播放页右上更多菜单在播放背景动画下闪烁的问题，改为系统操作面板。
- 优化播放队列编辑状态切换，避免删除/排序控件入场动画叠加导致卡顿。
- 修复首页与「全部专辑」专辑封面网格尺寸不稳定、加载后可能撑开的布局问题。
- 增强 QuickConnect ID 解析与登录兼容性：兼容多种 `Serv.php` 请求字段/返回结构，HTTPS 模式也可启用自签名证书信任。
- 调整首页顶部快捷入口宽度，让首屏能看到约 2 个完整入口并露出第三个入口，提示可横向滑动。

### 版本
- 发布版本号更新为 `1.2.3`。

## [1.2.2] - 2026-06-16

### 修复
- 修复英文启动页已保存服务器行的排版：服务器名、状态徽章与地址改为分层显示，避免 `Default` / 自动登录徽章把主机名挤断。
- 补齐设置页语言菜单、流式音质选项、服务器编辑器、队列编辑按钮、加载/重试/清除控件、播放列表空态等路径的多语言文案。
- 扩充 `zh-Hant` / `en` / `ja` / `ko` / `de` / `fr` 字典，减少非中文语言下的中文回落。

### 版本
- 发布版本号更新为 `1.2.2`。

## [1.2.1] - 2026-06-16

### 修复
- **多语言彻底清扫**：把之前遗漏的中文字面值全部接入 `LanguageManager.t`，覆盖：
  - 设置：「流式音质」「播放」「下载管理」「下载」「尚无下载」「已用空间」「清空全部下载」「歌曲」「编辑服务器」、切换服务器的 setStatus 三条提示
  - 浏览：「专辑」「所有歌曲」「排序」（含 4 种枚举值「按名称/按艺术家/按专辑/按年代」）「按年代」「最近添加」「接下来」「加入歌单」「取消喜欢/喜欢」「张专辑」「空目录」「文件夹」「智能列表/普通列表」「首歌」「加载更多失败」
  - 专辑详情：行内 swipe 与 contextMenu 的「取消喜欢/喜欢」
  - 播放器：评分子菜单的「x 星」；定时停止选项「剩余」「分钟」「小时」「停止时间」「将在…后停止播放」「时间点停止」；队列页「随机播放队列/播放队列」+ navigationTitle「队列」；菜单 accessibilityLabel「加入歌单」「取消喜欢/喜欢」；删除歌曲流程「该歌曲」「将通过 File Station 永久删除」；评分 status「已清除评分/已设为 x 星/评分失败」；删除 status「没有可删除的文件路径/删除任务已提交/删除失败」；「暂无歌词」
  - 歌曲信息：完整 Section/Field（基本/标题/艺术家/专辑/专辑艺术家/年代/流派/作曲/曲目/碟号/音频/时长/编码/比特率/文件大小/评分/位置/路径），「歌曲信息/编辑歌曲信息/本地覆盖/个人备注/写点什么…/保存修改？/确认保存」及两段长说明
  - 我的歌单：新建/重命名/删除/批量编辑/清空全部歌曲/播放选中/已选 x 首/将永久删除提示/「在播放器或歌曲菜单点击 ❤️ 添加」「在歌曲菜单选择「添加到歌单」加入」「内置」「歌单不存在」
  - 加入歌单 sheet：「新建歌单…/选择歌单/已包含/加入歌单/创建并选择」
  - 登录：「用户名/密码/OTP（可选）/6 位数字/记住密码/连接/正在连接.../登录/需要双重验证，请输入 OTP。/自动登录失败…」
  - 服务器编辑：模式枚举「直接连接」、QC 解析失败/已解析为/连接失败/账号启用了两步验证/配置已保存到服务器列表 等长 error 文案，「控制面板 → 用户与群组 →…」剪贴板文案
  - 电台：12 个国家名（中国/香港/台湾/日本/韩国/美国/英国/法国/德国/巴西/印度/澳大利亚）+「热门/搜索电台/没找到电台/换个关键词或切换分类。」
  - 赞助页：「微信赞赏码/支付宝/扫码赞助/关闭」+ 标题「赞助支持」
  - MiniPlayer：accessibilityLabel「队列」
- **L10n 字典扩充**：`zh-Hant / en / ja / ko` 各补 100+ 条新 key 翻译；`de / fr` 未覆盖到的回落到中文原文。
- **修复编译错误**：`AllAlbumsView.SortOption` / `AllSongsView.SortOption` / `ServerEditorView.Mode` 的 `label/title` 由 `@MainActor` 隔离的 `.t` 调用回退为返回中文 key，调用处 `.t` 翻译，避免 nonisolated 上下文编译错误。`SponsorView.SponsorMethod` 静态数据同上。


### 新增（四）
- **灵动岛 + 锁屏 Live Activity**：新增 `SynoMusicLive` Widget Extension 实现 ActivityKit 三态：
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

[Unreleased]: https://github.com/ZanwingMak/SynoMusic/compare/v1.3.4...HEAD
[1.3.4]: https://github.com/ZanwingMak/SynoMusic/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/ZanwingMak/SynoMusic/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/ZanwingMak/SynoMusic/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/ZanwingMak/SynoMusic/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.9...v1.3.0
[1.2.9]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.8...v1.2.9
[1.2.8]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.7...v1.2.8
[1.2.7]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.6...v1.2.7
[1.2.6]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.4...v1.2.6
[1.2.4]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/ZanwingMak/SynoMusic/compare/v1.2.0...v1.2.1
[1.0.0]: https://github.com/ZanwingMak/SynoMusic/releases/tag/v1.0.0
