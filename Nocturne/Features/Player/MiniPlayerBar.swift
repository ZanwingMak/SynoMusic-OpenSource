import SwiftUI

/// 浮于 TabBar 之上的迷你播放器。
struct MiniPlayerBar: View {
    @EnvironmentObject private var playback: PlaybackEngine
    @EnvironmentObject private var session: AppSession
    var onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); onTap() }) {
            GlassPanel(cornerRadius: 18) {
                HStack(spacing: Metrics.m) {
                    CoverArt(
                        url: session.client?.audioStation.songCoverURL(songID: playback.currentSong?.id ?? ""),
                        cornerRadius: 8,
                        fallbackSeed: playback.currentSong?.id ?? ""
                    )
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(playback.currentSong?.title ?? "")
                            .font(.nocBody.weight(.semibold))
                            .lineLimit(1)
                        Text(playback.currentSong?.artist ?? "")
                            .font(.nocLabel)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        playback.togglePlayPause()
                    } label: {
                        Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Button {
                        playback.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Metrics.m)
                .padding(.vertical, 10)
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            ProgressView(value: playback.duration > 0 ? playback.currentTime : 0, total: max(playback.duration, 0.01))
                .progressViewStyle(.linear)
                .tint(Theme.accent)
                .frame(height: 2)
                .padding(.horizontal, 6)
                .opacity(0.8)
        }
    }
}
