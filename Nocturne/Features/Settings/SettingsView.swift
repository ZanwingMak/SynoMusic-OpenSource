import SwiftUI

/// 设置：服务器、音质、下载、关于。
struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var playback: PlaybackEngine

    @State private var serverInfo: [String: String] = [:]
    @State private var editingProfile: ServerProfile?
    @State private var pendingDelete: ServerProfile?

    var body: some View {
        Form {
            currentServerSection
            serversSection
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
        .alert(
            "删除服务器",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )
        ) {
            Button("删除", role: .destructive) {
                if let p = pendingDelete {
                    if session.client?.profile.id == p.id {
                        Task { await signOut() }
                    }
                    serverStore.remove(p)
                }
                pendingDelete = nil
            }
            Button("取消", role: .cancel) { pendingDelete = nil }
        } message: {
            if let p = pendingDelete {
                Text("将移除「\(p.name)」与该服务器保存的密码。该操作不可撤销。")
            }
        }
    }

    // MARK: 当前会话

    private var currentServerSection: some View {
        Section("当前会话") {
            if let active = session.client?.profile {
                infoRow("名称", active.name)
                infoRow("地址", active.displayURL)
                infoRow("用户", active.username)
                if let v = serverInfo["version_string"] {
                    infoRow("Audio Station", v)
                }
                Button(role: .destructive) {
                    Task { await signOut() }
                } label: { Text("退出登录") }
            } else {
                Text("未登录").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 服务器列表（收货地址风格）

    private var serversSection: some View {
        Section {
            if serverStore.profiles.isEmpty {
                Text("还没有添加任何服务器。")
                    .foregroundStyle(.secondary)
                    .font(.nocCaption)
            } else {
                ForEach(serverStore.profiles) { p in
                    ServerRowItem(
                        profile: p,
                        isDefault: p.id == serverStore.activeProfileID,
                        isCurrentSession: p.id == session.client?.profile.id,
                        onTap: { Task { await switchSession(to: p) } },
                        onEdit: { editingProfile = p }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDelete = p
                        } label: { Label("删除", systemImage: "trash") }
                        Button { editingProfile = p } label: { Label("编辑", systemImage: "pencil") }
                            .tint(.blue)
                    }
                }
            }
            Button {
                editingProfile = ServerProfile(host: "", username: "")
            } label: {
                Label("添加服务器", systemImage: "plus")
            }
        } header: {
            Text("服务器")
        } footer: {
            Text("点击行设为默认；下次启动 App 会用默认服务器自动登录。点 ⓘ 编辑配置；左滑删除。")
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

    /// 切换会话到指定档案：设为默认 + 用 Keychain 密码 silent login。
    /// 切换成功后 RootView 的 `.id(client.profile.id)` 会重建 MainShellView，
    /// 各页面的缓存数据（专辑/艺术家/歌曲列表）随之失效并重新加载。
    private func switchSession(to p: ServerProfile) async {
        Haptics.tap()
        serverStore.setActive(p)
        // 已经是当前会话则只更新默认标记
        if p.id == session.client?.profile.id { return }
        guard let pwd = serverStore.password(for: p), !pwd.isEmpty else {
            playback.setStatus("「\(p.name)」未保存密码，请在登录页输入")
            await signOut()
            return
        }
        playback.stop()
        await session.signOut()
        let client = SynologyClient(profile: p)
        do {
            try await client.login(password: pwd)
            var updated = p
            updated.lastConnectedAt = Date()
            serverStore.upsert(updated)
            session.sign(in: client)
            playback.setStatus("已切换到「\(p.name)」")
            Haptics.success()
        } catch {
            playback.setStatus("切换失败：\((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
            Haptics.warning()
        }
    }
}

/// 服务器行：仿"收货地址"风格 —— 行 tap = 设默认，✓ 表示默认，ⓘ = 编辑。
private struct ServerRowItem: View {
    let profile: ServerProfile
    let isDefault: Bool
    let isCurrentSession: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            onTap()
        }) {
            HStack(spacing: Metrics.s + 4) {
                Image(systemName: isDefault ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(isDefault ? Theme.accent : Color.secondary.opacity(0.6))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(displayName)
                            .font(.nocBody.weight(.semibold))
                            .foregroundStyle(.primary)
                        if isCurrentSession {
                            tagPill("已登录", color: .green)
                        }
                        if isDefault {
                            tagPill("默认", color: Theme.accent)
                        }
                    }
                    Text("\(profile.username) @ \(profile.displayURL)")
                        .font(.nocLabel)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: { Haptics.tap(); onEdit() }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("编辑服务器")
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 备注名为空时回退到主机；保证列表行不出现空白条目。
    private var displayName: String {
        let trimmed = profile.name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? profile.host : trimmed
    }

    private func tagPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
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
