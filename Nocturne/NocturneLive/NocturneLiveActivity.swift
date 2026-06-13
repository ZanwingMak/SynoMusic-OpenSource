import ActivityKit
import SwiftUI
import WidgetKit

/// 灵动岛 / 锁屏胶囊：展示当前播放歌曲信息与进度。
struct NocturneLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NowPlayingActivityAttributes.self) { context in
            // 锁屏 / 通知中心展开样式
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.35))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开形态：四个区域
                DynamicIslandExpandedRegion(.leading) {
                    Cover(coverURL: context.state.coverURL)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.state.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressLine(
                        elapsed: context.state.elapsed,
                        duration: context.state.duration
                    )
                }
            } compactLeading: {
                Cover(coverURL: context.state.coverURL)
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            } compactTrailing: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.pink)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
            } minimal: {
                Image(systemName: context.state.isPlaying ? "waveform" : "music.note")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.pink)
                    .symbolEffect(.variableColor.iterative, isActive: context.state.isPlaying)
            }
        }
    }
}

// MARK: 子组件

private struct LockScreenView: View {
    let state: NowPlayingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Cover(coverURL: state.coverURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(state.artist)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                ProgressLine(elapsed: state.elapsed, duration: state.duration)
            }
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .font(.title)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct Cover: View {
    let coverURL: String?

    var body: some View {
        Group {
            if let coverURL, let url = URL(string: coverURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.42, blue: 0.65),
                    Color(red: 0.55, green: 0.20, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .foregroundStyle(.white)
        }
    }
}

private struct ProgressLine: View {
    let elapsed: TimeInterval
    let duration: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let ratio = duration > 0 ? min(max(elapsed / duration, 0), 1) : 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 3)
    }
}
