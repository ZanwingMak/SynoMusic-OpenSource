import SwiftUI

/// 设置：服务器、音质、下载、关于。
struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var playback: PlaybackEngine

    @State private var serverInfo: [String: String] = [:]
    @State private var editingProfile: ServerProfile?

    var body: some View {
        Form {
            currentServerSection
            qualitySection
            cacheSection
            othersSection
            aboutSection
        }
        .navigationTitle("设置")
        .task { await loadServerInfo() }
        .sheet(item: $editingProfile) { profile in
            ServerEditorView(profile: profile)
                .presentationDetents([.large])
        }
    }

    // MARK: 服务器

    private var currentServerSection: some View {
        Section("当前服务器") {
            if let p = serverStore.activeProfile {
                infoRow("名称", p.name)
                infoRow("地址", p.displayURL)
                infoRow("用户", p.username)
                if let v = serverInfo["version_string"] {
                    infoRow("Audio Station", v)
                }
                Button("编辑服务器") {
                    editingProfile = p
                }
                Button(role: .destructive) {
                    Task { await signOut() }
                } label: {
                    Text("退出登录")
                }
            }
            ForEach(serverStore.profiles.filter { $0.id != serverStore.activeProfileID }) { other in
                Button {
                    serverStore.setActive(other)
                    Task { await signOut() }  // 触发重新登录
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("切换到 \(other.name)")
                    }
                }
            }
            Button {
                editingProfile = ServerProfile(host: "", username: "")
            } label: {
                Label("添加服务器", systemImage: "plus")
            }
        }
    }

    private var qualitySection: some View {
        Section {
            Picker("流式音质", selection: $playback.quality) {
                ForEach(AudioQuality.allCases) { q in
                    Text(q.title).tag(q)
                }
            }
        } header: {
            Text("音质")
        } footer: {
            Text("原始音质直接传输源文件（FLAC/WAV 等）。低带宽下选择压缩可降低卡顿概率。")
        }
    }

    private var cacheSection: some View {
        Section("下载与缓存") {
            NavigationLink {
                DownloadsListView()
            } label: {
                HStack {
                    Label("已下载歌曲", systemImage: "arrow.down.circle")
                    Spacer()
                    Text("管理").foregroundStyle(.secondary)
                }
            }
        }
    }

    private var othersSection: some View {
        Section {
            Toggle(isOn: .constant(true)) {
                Label("锁屏控制", systemImage: "lock.open")
            }
            .disabled(true)
            Toggle(isOn: .constant(true)) {
                Label("AirPlay", systemImage: "airplayaudio")
            }
            .disabled(true)
        } header: {
            Text("其它")
        } footer: {
            Text("系统已默认开启。需要在控制中心使用 AirPlay 选择目标设备。")
        }
    }

    private var aboutSection: some View {
        Section("关于") {
            infoRow("版本", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            Link(destination: URL(string: "https://www.synology.com/en-global/dsm/feature/audio_station")!) {
                Label("Synology Audio Station", systemImage: "link")
            }
            Text("Nocturne 是一个非官方的 Audio Station 客户端。Synology 商标与 Audio Station 名称归群晖科技所有。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 形如 "字段 ······ 值" 的行。
    @ViewBuilder
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func loadServerInfo() async {
        guard let api = session.client?.audioStation else { return }
        if let info = try? await api.getInfo() { self.serverInfo = info }
    }

    private func signOut() async {
        playback.stop()
        await session.signOut()
    }
}

/// 已下载歌曲管理。
struct DownloadsListView: View {
    @StateObject private var downloads = DownloadManager()
    var body: some View {
        Group {
            if downloads.entries.isEmpty {
                EmptyStateView(systemImage: "arrow.down.circle", title: "尚无下载", message: "在歌曲长按菜单选择「下载」。")
            } else {
                List {
                    Section {
                        HStack {
                            Text("已用空间")
                            Spacer()
                            Text(downloads.totalBytes.humanSize)
                                .foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) { downloads.clearAll() } label: {
                            Text("清空全部下载")
                        }
                    }
                    Section("歌曲") {
                        ForEach(downloads.entries) { e in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title).font(.nocBody)
                                HStack {
                                    Text(e.artist ?? "").font(.nocLabel).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(e.size.humanSize).font(.nocLabel).foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) { downloads.remove(songID: e.id) } label: { Label("删除", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("下载管理")
    }
}
