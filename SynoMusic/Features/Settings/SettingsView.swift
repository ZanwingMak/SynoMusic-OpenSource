import SwiftUI

/// 设置：服务器、音质、下载、关于。
struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var playback: PlaybackEngine
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var lm: LanguageManager
    @EnvironmentObject private var playbackSettings: PlaybackSettings

    @State private var serverInfo: [String: String] = [:]
    @State private var editingProfile: ServerProfile?
    @State private var pendingDelete: ServerProfile?
    @State private var showSponsors: Bool = false

    var body: some View {
        Form {
            currentServerSection
            serversSection
            themeSection
            languageSection
            qualitySection
            cacheSection
            othersSection
            aboutSection
        }
        .navigationTitle("设置".t)
        .task { await loadServerInfo() }
        .sheet(item: $editingProfile) { profile in
            ServerEditorView(profile: profile)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSponsors) {
            SponsorListSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert(
            "删除服务器".t,
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )
        ) {
            Button("删除".t, role: .destructive) {
                if let p = pendingDelete {
                    if session.client?.profile.id == p.id {
                        Task { await signOut() }
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        serverStore.remove(p)
                    }
                }
                pendingDelete = nil
            }
            Button("取消".t, role: .cancel) { pendingDelete = nil }
        } message: {
            if let p = pendingDelete {
                Text("将移除「\(p.name)」与该服务器保存的密码。该操作不可撤销。".t)
            }
        }
    }

    // MARK: 当前会话

    private var currentServerSection: some View {
        Section("当前会话".t) {
            if let active = session.client?.profile {
                infoRow("名称".t, active.name)
                infoRow("地址".t, active.displayURL)
                infoRow("用户".t, active.username)
                if let v = serverInfo["version_string"] {
                    infoRow("Audio Station", v)
                }
                Button(role: .destructive) {
                    Task { await signOut() }
                } label: { Text("退出登录".t) }
            } else {
                Text("未登录".t).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 服务器列表（收货地址风格）

    private var serversSection: some View {
        Section {
            if serverStore.profiles.isEmpty {
                Text("还没有添加任何服务器。".t)
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            pendingDelete = p
                        } label: { Label("删除".t, systemImage: "trash") }
                        Button { editingProfile = p } label: { Label("编辑".t, systemImage: "pencil") }
                            .tint(.blue)
                    }
                }
            }
            Button {
                editingProfile = ServerProfile(host: "", username: "")
            } label: {
                Label("添加服务器".t, systemImage: "plus")
            }
        } header: {
            Text("服务器".t)
        } footer: {
            Text("点击行设为默认；下次启动 App 会用默认服务器自动登录。点 ⓘ 编辑配置；左滑删除。".t)
        }
    }

    private var themeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("强调色".t)
                    .font(.nocLabel)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(ThemeManager.palettes) { palette in
                            Button {
                                Haptics.tap()
                                theme.currentID = palette.id
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(palette.gradient)
                                        .frame(width: 44, height: 44)
                                    if theme.currentID == palette.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.headline)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(theme.currentID == palette.id ? Color.primary.opacity(0.4) : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                Picker("外观".t, selection: $theme.appearance) {
                    ForEach(AppearancePreference.allCases) { a in
                        Text(a.title.t).tag(a)
                    }
                }
                .pickerStyle(.segmented)
            }
        } header: {
            Text("外观".t)
        } footer: {
            Text("强调色与 Light/Dark 偏好；保存到本地。".t)
        }
    }

    private var languageSection: some View {
        Section {
            Picker(selection: $lm.current) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.title).tag(lang)
                }
            } label: {
                Label("语言".t, systemImage: "character.bubble")
            }
        } header: {
            Text("语言".t)
        }
    }

    private var qualitySection: some View {
        Section {
            Picker("流式音质".t, selection: $playback.quality) {
                ForEach(AudioQuality.allCases) { q in
                    Text(q.title).tag(q)
                }
            }
        } header: {
            Text("音质".t)
        } footer: {
            Text("原始音质直接传输源文件（FLAC/WAV 等）。低带宽下选择压缩可降低卡顿概率。".t)
        }
    }

    private var cacheSection: some View {
        Section("下载与缓存".t) {
            NavigationLink {
                DownloadsListView()
            } label: {
                HStack {
                    Label("已下载歌曲".t, systemImage: "arrow.down.circle")
                    Spacer()
                    Text("管理".t).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var othersSection: some View {
        Section {
            Toggle(isOn: $playbackSettings.backgroundPlaybackEnabled) {
                Label("后台播放".t, systemImage: "play.circle")
            }
            Toggle(isOn: $playbackSettings.lockScreenControlsEnabled) {
                Label("锁屏控制".t, systemImage: "lock.open")
            }
            Toggle(isOn: $playbackSettings.airPlayEnabled) {
                Label("AirPlay".t, systemImage: "airplayaudio")
            }
        } header: {
            Text("播放".t)
        } footer: {
            Text("关闭「后台播放」后，App 进入后台会自动暂停。AirPlay 关闭后，控制中心的路由选择仍可用但 SynoMusic 不会主动声明输出。".t)
        }
    }

    private var aboutSection: some View {
        Section("关于".t) {
            infoRow("版本".t, Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            Button {
                Haptics.tap()
                showSponsors = true
            } label: {
                HStack {
                    Label {
                        Text("赞助支持".t).foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "heart.circle.fill")
                            .foregroundStyle(.pink)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowSeparator(.visible)
            Link(destination: URL(string: "https://github.com/ZanwingMak/SynoMusic/issues")!) {
                Label("反馈问题".t, systemImage: "exclamationmark.bubble.fill")
            }
            Link(destination: URL(string: "https://github.com/ZanwingMak/SynoMusic")!) {
                Label("GitHub 仓库".t, systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Link(destination: URL(string: "https://github.com/ZanwingMak/SynoMusic/blob/main/CHANGELOG.md")!) {
                Label("更新日志".t, systemImage: "list.bullet.rectangle")
            }
            Text("SynoMusic 是一个非官方的 Audio Station 客户端。Synology 商标与 Audio Station 名称归群晖科技所有。".t)
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
            playback.setStatus("「\(p.name)」" + "未保存密码，请在登录页输入".t)
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
            playback.setStatus("已切换到".t + "「\(p.name)」")
            Haptics.success()
        } catch {
            playback.setStatus("切换失败".t + "：\((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)")
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
                        if profile.isQuickConnect {
                            tagPill("QC", color: .blue)
                        }
                        if isCurrentSession {
                            tagPill("已登录".t, color: .green)
                        }
                        if isDefault {
                            tagPill("默认".t, color: Theme.accent)
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
                .accessibilityLabel("编辑服务器".t)
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
                EmptyStateView(systemImage: "arrow.down.circle", title: "尚无下载".t, message: "在歌曲长按菜单选择「下载」。".t)
            } else {
                List {
                    Section {
                        HStack {
                            Text("已用空间".t)
                            Spacer()
                            Text(downloads.totalBytes.humanSize)
                                .foregroundStyle(.secondary)
                        }
                        Button(role: .destructive) { downloads.clearAll() } label: {
                            Text("清空全部下载".t)
                        }
                    }
                    Section("歌曲".t) {
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
                                Button(role: .destructive) { downloads.remove(songID: e.id) } label: { Label("删除".t, systemImage: "trash") }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("下载管理".t)
    }
}
