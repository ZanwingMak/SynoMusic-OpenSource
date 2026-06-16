import Foundation
import AVFoundation
import UIKit

/// 播放相关偏好开关：后台播放 / 锁屏控制 / AirPlay。
/// 全部持久化到 UserDefaults，并对 AVAudioSession 实时生效。
@MainActor
final class PlaybackSettings: ObservableObject {
    @Published var backgroundPlaybackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundPlaybackEnabled, forKey: bgKey)
            UserDefaults.standard.synchronize()
            applyAudioSession()
        }
    }
    @Published private(set) var lockScreenControlsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(lockScreenControlsEnabled, forKey: lockKey)
            UserDefaults.standard.synchronize()
        }
    }
    @Published private(set) var airPlayEnabled: Bool {
        didSet {
            UserDefaults.standard.set(airPlayEnabled, forKey: airKey)
            UserDefaults.standard.synchronize()
            applyAudioSession()
        }
    }

    private let bgKey = "syno.playback.background"
    private let lockKey = "syno.playback.lockscreen"
    private let airKey = "syno.playback.airplay"

    init() {
        let defaults = UserDefaults.standard
        self.backgroundPlaybackEnabled = defaults.object(forKey: bgKey) as? Bool ?? true
        self.lockScreenControlsEnabled = true
        self.airPlayEnabled = true
        defaults.set(true, forKey: lockKey)
        defaults.set(true, forKey: airKey)
    }

    /// 根据当前开关重新配置 AVAudioSession。
    func applyAudioSession() {
        let session = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = []
        options.insert(.allowAirPlay)
        options.insert(.allowBluetoothA2DP)
        do {
            try session.setCategory(
                backgroundPlaybackEnabled ? .playback : .ambient,
                mode: .default,
                options: options
            )
            try session.setActive(true, options: [])
        } catch {
            // 静默：失败时仍能前台播放
        }
    }
}
