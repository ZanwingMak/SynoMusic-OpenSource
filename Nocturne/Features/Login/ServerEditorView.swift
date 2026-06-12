import SwiftUI

/// 服务器档案编辑：新增或编辑 NAS 连接信息；同时承担"测试并登录"功能。
///
/// 布局策略：把常用 5 件（协议/主机/端口/用户名/密码 + 连接按钮）压缩在第一屏，
/// 二步验证、信任自签、记住密码、备注名等次要项目折叠在「高级」中默认隐藏。
struct ServerEditorView: View {
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var session: AppSession
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

    /// 编辑模式：表单标题与额外按钮以此判定。
    private var isEditingExisting: Bool {
        serverStore.profiles.contains(where: { $0.id == profile.id })
    }

    var body: some View {
        NavigationStack {
            Form {
                connectionSection
                accountSection
                actionSection
                advancedSection
            }
            .navigationTitle(isEditingExisting ? "编辑服务器" : "添加服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert(
                "连接失败",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("我知道了", role: .cancel) { error = nil }
                if (error ?? "").contains("Audio Station") {
                    Button("复制 DSM 路径") {
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

    /// 连接：协议 / 主机 / 端口（默认显示，第一屏可见）。
    private var connectionSection: some View {
        Section {
            Picker("协议", selection: $profile.scheme) {
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
            TextField("主机或 QuickConnect ID", text: $profile.host)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.URL)
            HStack {
                Text("端口")
                Spacer()
                TextField("5000", text: $portText)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 120)
                    .onChange(of: portText) { _, new in
                        let digits = new.filter(\.isNumber)
                        if digits != new { portText = digits }
                        if let v = Int(digits), v > 0, v <= 65535 { profile.port = v }
                    }
            }
        } header: {
            Text("连接")
        }
    }

    /// 账号：用户名 + 密码（第一屏可见）。
    private var accountSection: some View {
        Section {
            TextField("用户名", text: $profile.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            HStack {
                Group {
                    if passwordVisible {
                        TextField("密码", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    } else {
                        SecureField("密码", text: $password)
                    }
                }
                .textContentType(.password)
                .submitLabel(.done)
                Button { passwordVisible.toggle() } label: {
                    Image(systemName: passwordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("账号")
        }
    }

    /// 主按钮：直接放在账号下方，第一屏可见。
    private var actionSection: some View {
        Section {
            Button {
                Task { await connectAndSave() }
            } label: {
                HStack {
                    if isConnecting {
                        ProgressView().tint(.white)
                    }
                    Text(isConnecting ? "正在连接..." : "连接并保存")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .listRowBackground(Color.clear)
            .disabled(!canSubmit || isConnecting)
        }
    }

    /// 高级：折叠收纳次要选项。
    private var advancedSection: some View {
        Section {
            DisclosureGroup(isExpanded: $advancedExpanded) {
                TextField("备注名（家里的 DS220+）", text: $profile.name)
                    .textInputAutocapitalization(.never)
                TextField("二步验证码（OTP）", text: $otp)
                    .keyboardType(.numberPad)
                Toggle("记住密码", isOn: $rememberPassword)
                if profile.scheme == .https {
                    Toggle("信任自签名证书", isOn: $profile.ignoreInvalidCertificate)
                }
                if isEditingExisting {
                    Button("仅保存配置，不立即登录") { saveOnly() }
                }
            } label: {
                Label("高级", systemImage: "slider.horizontal.3")
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("默认 HTTP 5000、HTTPS 5001；启用了二步验证的账号需在「高级」填入 OTP。密码加密保存于 Keychain。")
        }
    }

    // MARK: 行为

    private var canSubmit: Bool {
        !profile.host.trimmingCharacters(in: .whitespaces).isEmpty
            && !profile.username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && profile.port > 0 && profile.port <= 65535
    }

    private func setupOnAppear() {
        portText = String(profile.port)
        // 关键：新增模式下强制清空密码，避免系统 / SwiftUI 复用残留
        if isEditingExisting {
            password = serverStore.password(for: profile) ?? ""
        } else {
            password = ""
        }
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-password"), i + 1 < args.count {
            password = args[i + 1]
        }
        // -autoconnect 在整个进程生命周期内只触发一次，防止反复打开 editor 都自动连接
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
    /// `-autoconnect` 触发节流：每个进程只在第一个 editor 出现时触发一次。
    private static var autoconnectFired: Bool = false
    #endif

    private func saveOnly() {
        var p = profile
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty { p.name = p.host }
        serverStore.upsert(p)
        if rememberPassword, !password.isEmpty {
            try? serverStore.savePassword(password, for: p)
        }
        Haptics.success()
        dismiss()
    }

    /// 真实发起 SYNO.API.Auth Login 请求；成功后落库 + 登录。
    private func connectAndSave() async {
        guard canSubmit else { return }
        isConnecting = true
        defer { isConnecting = false }
        error = nil

        var p = profile
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty { p.name = p.host }

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
            self.error = "账号启用了两步验证。请展开「高级」填入 6 位 OTP 代码后再试。"
            advancedExpanded = true
            Haptics.warning()
        } catch let err as SynologyError {
            self.error = err.errorDescription
            Haptics.warning()
        } catch {
            self.error = error.localizedDescription
            Haptics.warning()
        }
    }
}
