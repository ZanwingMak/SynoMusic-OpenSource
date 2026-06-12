import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

/// 重复模式。
enum RepeatMode: String, CaseIterable {
    case off, all, one
}

/// 音质设置。
enum AudioQuality: String, CaseIterable, Identifiable {
    case original     // raw 流，不转码
    case high         // 320 kbps mp3
    case standard     // 128 kbps mp3

    var id: String { rawValue }
    var title: String {
        switch self {
        case .original: return "原始音质"
        case .high: return "高品质 320kbps"
        case .standard: return "标准 128kbps"
        }
    }
    /// 对应 streamURL 的 format 参数。
    var streamFormat: String {
        switch self {
        case .original: return "raw"
        case .high: return "mp3"
        case .standard: return "mp3"
        }
    }
}

/// 全局播放引擎：单例式注入到 SwiftUI 环境，掌管队列、时间、Now Playing、远程命令。
@MainActor
final class PlaybackEngine: ObservableObject {
    // MARK: 公开状态

    @Published private(set) var queue: [Song] = []
    @Published private(set) var currentIndex: Int = -1
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var isBuffering: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isShuffling: Bool = false
    @Published var quality: AudioQuality = .original
    @Published private(set) var lyrics: [LyricLine] = []
    @Published private(set) var currentLyricIndex: Int? = nil
    /// 用户可见的瞬时状态消息（错误、Demo 提示等）；nil 表示无消息。
    @Published private(set) var statusMessage: String?

    /// 当前歌曲。
    var currentSong: Song? {
        guard queue.indices.contains(currentIndex) else { return nil }
        return queue[currentIndex]
    }

    /// 当前 API 客户端，由外部注入。
    weak var apiClient: SynologyClient?

    // MARK: 私有

    private var player: AVQueuePlayer = AVQueuePlayer()
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?
    private var stallObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    /// 当前曲目的 status 订阅；切歌时取消。
    private var statusCancel: AnyCancellable?
    private var bag = Set<AnyCancellable>()
    private var originalQueue: [Song] = []   // 用于关闭随机时还原
    private var demoTicker: Task<Void, Never>?
    private var statusClearTask: Task<Void, Never>?
    /// 是否正处于 Demo 模拟（apiClient 为 nil 但用户仍点歌的场景）。
    private var isDemoPlayback: Bool = false

    init() {
        setupAudioSession()
        setupRemoteCommands()
        setupTimeObserver()
        setupEndObserver()
    }

    // 不实现 deinit：PlaybackEngine 是 App 生命周期单例，观察者随进程退出自然释放；
    // Swift 6 严格并发禁止 nonisolated deinit 访问 main-actor 状态。

    // MARK: 公开操作

    /// 替换队列并从指定下标开始播放。
    func play(queue songs: [Song], startAt index: Int = 0) {
        guard !songs.isEmpty else { return }
        self.originalQueue = songs
        var ordered = songs
        if isShuffling { ordered = shuffledKeepingHead(songs, head: index) }
        self.queue = ordered
        self.currentIndex = ordered.indices.contains(index) ? index : 0
        // 立即给用户视觉反馈，避免"点了没反应"的错觉
        if let title = currentSong?.title {
            setStatus("正在加载：\(title)")
        }
        loadCurrent(autoPlay: true)
    }

    /// 添加单曲到队尾（"接下来播放"）。
    func appendNext(_ song: Song) {
        if queue.isEmpty {
            play(queue: [song])
        } else {
            queue.insert(song, at: min(currentIndex + 1, queue.count))
        }
    }

    /// 切换播放/暂停。
    func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }

    func resume() {
        if isDemoPlayback {
            isPlaying = true
            startDemoTicker()
            updateNowPlayingPlaybackState()
            return
        }
        // 若从未加载，尝试加载当前。
        if player.currentItem == nil { loadCurrent(autoPlay: true); return }
        player.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    func stop() {
        player.pause()
        player.removeAllItems()
        demoTicker?.cancel()
        isDemoPlayback = false
        isPlaying = false
        queue = []
        currentIndex = -1
        currentTime = 0
        duration = 0
        dismissStatus()
        clearNowPlaying()
    }

    func next() {
        guard !queue.isEmpty else { return }
        if currentIndex + 1 < queue.count {
            currentIndex += 1
            loadCurrent(autoPlay: true)
        } else if repeatMode == .all {
            currentIndex = 0
            loadCurrent(autoPlay: true)
        } else {
            pause()
        }
    }

    func previous() {
        guard !queue.isEmpty else { return }
        // 若播放过 3s，回到曲头；否则上一首。
        if currentTime > 3 {
            seek(to: 0)
        } else if currentIndex > 0 {
            currentIndex -= 1
            loadCurrent(autoPlay: true)
        } else {
            seek(to: 0)
        }
    }

    func seek(to time: TimeInterval) {
        if isDemoPlayback {
            currentTime = max(0, min(time, duration))
            updateNowPlayingPlaybackState()
            return
        }
        let target = CMTime(seconds: max(0, time), preferredTimescale: 600)
        player.seek(to: target) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time
                self.updateNowPlayingPlaybackState()
            }
        }
    }

    func toggleShuffle() {
        isShuffling.toggle()
        if isShuffling, !queue.isEmpty {
            queue = shuffledKeepingHead(queue, head: currentIndex)
            currentIndex = 0
        } else if !isShuffling, !originalQueue.isEmpty, let cur = currentSong {
            queue = originalQueue
            currentIndex = queue.firstIndex(of: cur) ?? 0
        }
    }

    func cycleRepeatMode() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
    }

    /// 选定队列中的一项播放。
    func playItem(at index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        loadCurrent(autoPlay: true)
    }

    /// 从队列移除一项。
    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        if index == currentIndex {
            queue.remove(at: index)
            if queue.isEmpty { stop() } else {
                if currentIndex >= queue.count { currentIndex = queue.count - 1 }
                loadCurrent(autoPlay: true)
            }
        } else {
            if index < currentIndex { currentIndex -= 1 }
            queue.remove(at: index)
        }
    }

    /// 重排队列。
    func moveInQueue(from offsets: IndexSet, to destination: Int) {
        let cur = currentSong
        queue.move(fromOffsets: offsets, toOffset: destination)
        if let cur, let idx = queue.firstIndex(of: cur) { currentIndex = idx }
    }

    // MARK: 内部加载

    private func loadCurrent(autoPlay: Bool) {
        guard let song = currentSong else { return }
        // 未连接服务器：进入 Demo 模拟，UI 跟着时间走但不发出声音
        guard let api = apiClient?.audioStation else {
            startDemoPlayback(for: song, autoPlay: autoPlay)
            return
        }
        guard let url = api.streamURL(songID: song.id, format: quality.streamFormat) else {
            setStatus("无法构造流地址：\(song.title)")
            return
        }
        isDemoPlayback = false
        demoTicker?.cancel()

        let item = AVPlayerItem(url: url)
        player.removeAllItems()
        player.insert(item, after: nil)

        isBuffering = true
        observeStall(for: item)
        observeFailure(for: item)

        if autoPlay {
            player.play()
            isPlaying = true
        }

        Task { @MainActor in
            await self.refreshDuration()
            await self.fetchLyricsAsync(for: song)
            self.updateNowPlayingMetadata()
        }
    }

    /// Demo 模拟：UI 上时间线走，但不真正出声。
    private func startDemoPlayback(for song: Song, autoPlay: Bool) {
        isDemoPlayback = true
        demoTicker?.cancel()
        player.pause()
        player.removeAllItems()
        duration = song.duration > 0 ? song.duration : 240
        currentTime = 0
        isBuffering = false
        isPlaying = autoPlay
        setStatus("演示模式：尚未连接服务器，未真实播放。", persistent: true)
        updateNowPlayingMetadata()
        if autoPlay { startDemoTicker() }
    }

    private func startDemoTicker() {
        demoTicker?.cancel()
        demoTicker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    guard let self else { return }
                    guard self.isPlaying, self.isDemoPlayback else { return }
                    let next = min(self.currentTime + 0.5, self.duration)
                    self.currentTime = next
                    self.updateCurrentLyric()
                    self.updateNowPlayingPlaybackState()
                    if next >= self.duration { self.next() }
                }
            }
        }
    }

    /// 设置一条状态消息；`persistent=false` 时 4 秒后自动清除。
    func setStatus(_ message: String?, persistent: Bool = false) {
        statusMessage = message
        statusClearTask?.cancel()
        if let message, !persistent, !message.isEmpty {
            statusClearTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                await MainActor.run { self?.statusMessage = nil }
            }
        }
    }

    /// UI 关闭 Toast 时调用。
    func dismissStatus() {
        statusClearTask?.cancel()
        statusMessage = nil
    }

    /// 监听 AVPlayerItem 失败事件，转成可见错误。
    /// 注意：必须用 Combine + `receive(on: .main)` 把回调引回主线程，
    /// 否则 KVO 在非主线程触发 `@MainActor` 隔离检查会让 Swift 6 直接 SIGTRAP。
    private func observeFailure(for item: AVPlayerItem) {
        if let obs = failObserver { NotificationCenter.default.removeObserver(obs) }
        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item, queue: .main
        ) { [weak self] note in
            let err = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            Task { @MainActor in
                self?.setStatus("播放中断：\(err?.localizedDescription ?? "未知错误")")
            }
        }
        statusCancel?.cancel()
        statusCancel = item.publisher(for: \.status, options: [.new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.isBuffering = false
                    self.dismissStatus()
                case .failed:
                    let reason = item?.error?.localizedDescription ?? "未知错误"
                    self.setStatus("无法播放：\(reason)")
                    self.isBuffering = false
                    self.isPlaying = false
                default:
                    break
                }
            }
    }

    private func refreshDuration() async {
        guard let item = player.currentItem else { return }
        do {
            let asset = item.asset
            let d = try await asset.load(.duration)
            self.duration = CMTimeGetSeconds(d).isFinite ? CMTimeGetSeconds(d) : (currentSong?.duration ?? 0)
        } catch {
            self.duration = currentSong?.duration ?? 0
        }
        isBuffering = false
    }

    private func fetchLyricsAsync(for song: Song) async {
        guard let api = apiClient?.audioStation else {
            self.lyrics = []; return
        }
        do {
            let lines = try await api.getLyrics(songID: song.id)
            self.lyrics = lines
        } catch {
            self.lyrics = []
        }
    }

    // MARK: Audio Session / Remote / Observers

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // 没拿到 audio session 不影响 UI 渲染，仅静默
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            // queue: .main 保证在 main queue 上，但 Swift 6 严格并发要求显式 actor hop。
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = CMTimeGetSeconds(time)
                self.updateCurrentLyric()
                self.updateNowPlayingPlaybackState()
            }
        }
    }

    private func setupEndObserver() {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.repeatMode == .one {
                    self.seek(to: 0)
                    self.player.play()
                } else {
                    self.next()
                }
            }
        }
    }

    private func observeStall(for item: AVPlayerItem) {
        if let obs = stallObserver { NotificationCenter.default.removeObserver(obs) }
        stallObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.isBuffering = true }
        }
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let pos = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: pos.positionTime) }
            return .success
        }
    }

    private func updateNowPlayingMetadata() {
        guard let song = currentSong else { clearNowPlaying(); return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist ?? "",
            MPMediaItemPropertyAlbumTitle: song.album ?? "",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // 异步抓封面：下载在 @MainActor，但 MPMediaItemArtwork 的 handler 闭包
        // 必须在 nonisolated 上下文里创建——MediaPlayer 会在它自己的 accessQueue
        // 上调用这个闭包，闭包若被绑定到 @MainActor，runtime 会主动 SIGTRAP。
        if let api = apiClient?.audioStation, let url = api.songCoverURL(songID: song.id) {
            Task { @MainActor [weak self] in
                guard self != nil else { return }
                guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
                guard let image = UIImage(data: data) else { return }
                Self.attachArtwork(image)
            }
        }
    }

    /// nonisolated 静态方法：构造 MPMediaItemArtwork 并合并进 NowPlaying。
    /// 必须 nonisolated，否则它内部生成的 handler 闭包会继承 @MainActor 隔离，
    /// 在 MediaPlayer 的 accessQueue 上回调时触发 swift_task_checkIsolated 崩溃。
    nonisolated private static func attachArtwork(_ image: UIImage) {
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        var current = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        current[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = current
    }

    private func updateNowPlayingPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func updateCurrentLyric() {
        guard !lyrics.isEmpty else {
            currentLyricIndex = nil; return
        }
        // 二分定位最后一个 timestamp <= currentTime 的行。
        var lo = 0, hi = lyrics.count - 1, found: Int? = nil
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lyrics[mid].timestamp <= currentTime {
                found = mid; lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        if currentLyricIndex != found { currentLyricIndex = found }
    }

    /// 保证 head 仍在首位，其余打乱。
    private func shuffledKeepingHead(_ songs: [Song], head: Int) -> [Song] {
        guard songs.indices.contains(head) else { return songs.shuffled() }
        let h = songs[head]
        var rest = songs
        rest.remove(at: head)
        rest.shuffle()
        return [h] + rest
    }
}
