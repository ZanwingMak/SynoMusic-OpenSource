import SwiftUI

/// 定时停止 sheet：定时分钟数 / 本曲结束 / 关闭。
struct SleepTimerSheet: View {
    @EnvironmentObject private var playback: PlaybackEngine
    @Binding var isPresented: Bool

    private static let presets: [Int] = [5, 10, 15, 30, 45, 60, 90]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let remain = playback.sleepRemaining {
                        HStack {
                            Image(systemName: "moon.zzz.fill").foregroundStyle(Theme.accent)
                            Text("剩余 \(format(remain))")
                                .monospacedDigit()
                            Spacer()
                            Button("取消") {
                                playback.setSleepTimer(nil)
                                Haptics.tap()
                            }
                            .foregroundStyle(.red)
                        }
                    } else if playback.stopAtTrackEnd {
                        HStack {
                            Image(systemName: "stop.circle.fill").foregroundStyle(Theme.accent)
                            Text("本曲结束后停止")
                            Spacer()
                            Button("取消") {
                                playback.setSleepTimer(nil)
                                Haptics.tap()
                            }
                            .foregroundStyle(.red)
                        }
                    } else {
                        Label("当前未设置", systemImage: "moon.zzz")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("倒计时") {
                    ForEach(Self.presets, id: \.self) { mins in
                        Button {
                            Haptics.soft()
                            playback.setSleepTimer(TimeInterval(mins * 60))
                            isPresented = false
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundStyle(Theme.accent)
                                Text("\(mins) 分钟")
                                Spacer()
                            }
                        }
                    }
                }

                Section("按曲结束") {
                    Button {
                        Haptics.soft()
                        playback.enableStopAtTrackEnd()
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle").foregroundStyle(Theme.accent)
                            Text("本曲结束后停止")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("定时停止")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { isPresented = false }
                }
            }
        }
    }

    private func format(_ s: TimeInterval) -> String {
        let total = max(0, Int(s))
        let h = total / 3600
        let m = (total % 3600) / 60
        let sec = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }
}
