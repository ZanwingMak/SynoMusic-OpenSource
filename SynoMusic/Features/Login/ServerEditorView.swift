import SwiftUI

/// 服务器档案编辑：新增或编辑 NAS 连接信息；同时承担"测试并登录"功能。
struct ServerEditorView: View {
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var playback: PlaybackEngine
    @Environment(\.dismiss) private var dismiss

    @State var profile: ServerProfile
    @State private var password: String = ""
    @State private var otp: String = ""
    @State private var portText: String = ""
    @State private var passwordVisible: Bool = false
    @State private var rememberPassword: Bool = true
    @State private var advancedExpanded: Bool = false

    @State private var isConnecting: Bool = false
    @State private var error: String?

    /// 编辑模式（QC / 直连）。
    enum Mode: String, CaseIterable, Identifiable {
        case direct, quickConnect
        var id: String { rawValue }
        var title: String {
            switch self {
            case .direct: return "直接连接"
            case .quickConnect: return "QuickConnect"
            }
        }
    }
    @State private var mode: Mode = .direct

    private var loadingShown: Bool {
        #if DEBUG
        return isConnecting || ProcessInfo.processInfo.arguments.contains("-fakeloading")
        #else
        return isConnecting
        #endif
    }

    private var isEditingExisting: Bool {
        serverStore.profiles.contains(where: { $0.id == profile.id })
    }

    var body: some View {
        NavigationStack {
            Form {
                modeSection
                if mode == .quickConnect { quickConnectSection } else { directSection }
                accountSection
                actionSection
                advancedSection
            }
            .navigationTitle((isEditingExisting ? "编辑服务器" : "添加服务器").t)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消".t) { dismiss() }
                }
            }
            .alert(
                "连接失败".t,
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("我知道了".t, role: .cancel) { error = nil }
                if (error ?? "").contains("Audio Station") {
                    Button("复制 DSM 路径".t) {
                        UIPasteboard.general.string = "控制面板 → 用户与群组 → 编辑用户 → 应用程序 → Audio Station → 允许"
                    }
                }
            } message: {
                Text(error ?? "")
            }
            .onAppear { setupOnAppear() }
        }
    }

    // MARK: 章节

    private var modeSection: some View {
        Section {
            Picker("模式".t, selection: $mode) {
                ForEach(Mode.allCases) { m in Text(m.title.t).tag(m) }
            }
            .pickerStyle(.segmented)
        } footer: {
            Text(mode == .quickConnect
                ? "QuickConnect ID 由群晖服务解析为真实地址，无需自己填 IP 与端口。".t
                : "直连 IP / DDNS 域名，自行指定协议和端口。".t)
        }
    }

    /// QuickConnect 模式：只需 ID + 通道（HTTP/HTTPS）。
    private var quickConnectSection: some View {
        Section {
            ClearableTextField(title: "QuickConnect ID", text: $profile.quickConnectID, keyboard: .URL)
            Picker("通道".t, selection: $profile.scheme) {
                ForEach(ServerProfile.Scheme.allCases) { s in
                    Text(s.rawValue.uppercased()).tag(s)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("QuickConnect")
        } footer: {
            Text("在 DSM 控制面板 → QuickConnect 中查到的 ID（不包含 quickconnect.to 域名）。HTTP 走 dsm_portal 通道，HTTPS 走 dsm_portal_https 通道。".t)
        }
    }

    /// 直连模式：协议 / 主机 / 端口。
    private var directSection: some View {
        Section {
            Picker("协议".t, selection: $profile.scheme) {
                ForEach(ServerProfile.Scheme.allCases) { s in
                    Text(s.rawValue.uppercased()).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: profile.scheme) { _, newValue in
                let defaultsToFollow: Set<Int> = [5000, 5001]
                if defaultsToFollow.contains(profile.port) {
                    profile.port = (newValue == .https) ? 5001 : 5000
                    portText = String(profile.port)
                }
            }
            ClearableTextField(title: "主机或 DDNS".t, text: $profile.host, keyboard: .URL)
            HStack {
                Text("端口".t)
                Spacer()
                ClearableTextField(title: "5000", text: $portText, keyboard: .numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
                    .onChange(of: portText) { _, new in
                        let digits = new.filter(\.isNumber)
                        if digits != new { portText = digits }
                        if let v = Int(digits), v > 0, v <= 65535 { profile.port = v }
                    }
            }
        } header: {
            Text("连接".t)
        }
    }

    private var accountSection: some View {
        Section {
            ClearableTextField(title: "用户名".t, text: $profile.username)
            ClearableSecureField(title: "密码".t, text: $password)
        } header: {
            Text("账号".t)
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                Task { await connectAndSave() }
            } label: {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    if loadingShown {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.9)
                    }
                    Text(loadingShown ? "正在连接...".t : "连接并保存".t)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
            .disabled(!canSubmit || isConnecting)
        }
    }

    private var advancedSection: some View {
        Section {
            DisclosureGroup(isExpanded: $advancedExpanded) {
                ClearableTextField(title: "备注名（家里的 DS220+）".t, text: $profile.name, autocapitalization: .sentences)
                ClearableTextField(title: "二步验证码（OTP）".t, text: $otp, keyboard: .numberPad)
                Toggle("记住密码".t, isOn: $rememberPassword)
                if mode == .direct, profile.scheme == .https {
                    Toggle("信任自签名证书".t, isOn: $profile.ignoreInvalidCertificate)
                }
                if isEditingExisting {
                    Button("仅保存配置，不立即登录".t) { saveOnly() }
                }
            } label: {
                Label("高级".t, systemImage: "slider.horizontal.3")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("启用了二步验证的账号需在「高级」填入 OTP。密码加密保存于 Keychain。".t)
        }
    }

    // MARK: 行为

    private var canSubmit: Bool {
        guard !profile.username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else { return false }
        switch mode {
        case .quickConnect:
            return !profile.quickConnectID.trimmingCharacters(in: .whitespaces).isEmpty
        case .direct:
            return !profile.host.trimmingCharacters(in: .whitespaces).isEmpty
                && profile.port > 0 && profile.port <= 65535
        }
    }

    private func setupOnAppear() {
        portText = String(profile.port)
        // 编辑现有档案：用 isQuickConnect 字段决定初始模式
        if isEditingExisting {
            mode = profile.isQuickConnect ? .quickConnect : .direct
            password = serverStore.password(for: profile) ?? ""
        } else {
            // 添加新档案：强制清空密码，避免 SwiftUI 复用 / 系统自动填残留
            password = ""
            mode = .direct
        }
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-password"), i + 1 < args.count { password = args[i + 1] }
        if args.contains("-autoconnect"), !Self.autoconnectFired {
            Self.autoconnectFired = true
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                await connectAndSave()
            }
        }
        #endif
    }

    #if DEBUG
    private static var autoconnectFired: Bool = false
    #endif

    private func saveOnly() {
        var p = applyMode(to: profile)
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty { p.name = displayName(of: p) }
        serverStore.upsert(p)
        if rememberPassword, !password.isEmpty {
            try? serverStore.savePassword(password, for: p)
        }
        Haptics.success()
        dismiss()
    }

    /// 把当前编辑器 mode 反映到 profile 上（QC 模式下补 isQuickConnect / quickConnectID）。
    private func applyMode(to p: ServerProfile) -> ServerProfile {
        var copy = p
        copy.isQuickConnect = (mode == .quickConnect)
        if mode == .quickConnect {
            // 把 ID 也塞到 host 字段，让 QC resolver 能识别
            copy.host = copy.quickConnectID
        } else {
            copy.quickConnectID = ""
        }
        return copy
    }

    /// 列表显示名：QC 模式优先用 ID。
    private func displayName(of p: ServerProfile) -> String {
        if p.isQuickConnect, !p.quickConnectID.isEmpty { return p.quickConnectID }
        return p.host
    }

    private func connectAndSave() async {
        guard canSubmit else { return }
        isConnecting = true
        defer { isConnecting = false }
        error = nil

        var p = applyMode(to: profile)
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty { p.name = displayName(of: p) }

        // QuickConnect 模式：通过 resolver 把 ID 换成真实 host:port
        if p.isQuickConnect {
            playback.setStatus("正在解析 QuickConnect ID…".t)
            do {
                let resolved = try await QuickConnectResolver().resolve(
                    p.quickConnectID,
                    preferred: p.scheme,
                    report: { [weak playback] msg in playback?.setStatus(msg) }
                )
                p.host = resolved.host
                p.port = resolved.port
                p.scheme = resolved.scheme
                playback.setStatus("已解析为 \(resolved.scheme.rawValue.uppercased()) \(resolved.host):\(resolved.port)")
            } catch {
                self.error = "QuickConnect 解析失败：\(error.localizedDescription)\n\n注：iOS 模拟器对 QuickConnect 端点有网络栈限制，真机/Mac 上可正常解析。也可改用直连模式输入 IP 或 DDNS。"
                Haptics.warning()
                return
            }
        }

        // 立即 upsert 一份基础配置，登录成败都留得下
        serverStore.upsert(p)

        let client = SynologyClient(profile: p)
        do {
            try await client.login(password: password, otp: otp.isEmpty ? nil : otp)
            p.lastConnectedAt = Date()
            serverStore.upsert(p)
            serverStore.setActive(p)
            if rememberPassword {
                try? serverStore.savePassword(password, for: p)
            }
            session.sign(in: client)
            Haptics.success()
            dismiss()
        } catch let SynologyError.api(code, _) where code == 403 {
            self.error = "账号启用了两步验证。请展开「高级」填入 6 位 OTP 代码后再试。配置已保存到「服务器」列表，可稍后重试。"
            advancedExpanded = true
            Haptics.warning()
        } catch let err as SynologyError {
            self.error = (err.errorDescription ?? "连接失败") + "\n\n配置已保存到「服务器」列表，可在列表中点 ⓘ 修改后重试。"
            Haptics.warning()
        } catch {
            self.error = error.localizedDescription + "\n\n配置已保存到「服务器」列表。"
            Haptics.warning()
        }
    }
}
