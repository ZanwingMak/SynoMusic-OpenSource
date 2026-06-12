import SwiftUI

/// 服务器档案编辑：新增或编辑 NAS 连接信息；同时承担"测试并登录"功能。
struct ServerEditorView: View {
    @EnvironmentObject private var serverStore: ServerStore
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    @State var profile: ServerProfile
    /// 是否记住密码到 Keychain；保存即登录则强制为 true。
    @State private var password: String = ""
    @State private var otp: String = ""
    @State private var portText: String = ""
    @State private var passwordVisible: Bool = false
    @State private var rememberPassword: Bool = true

    @State private var isConnecting: Bool = false
    @State private var error: String?

    /// 编辑模式：编辑现有档案时禁用"连接并保存"为唯一选项，提供"仅保存"。
    private var isEditingExisting: Bool {
        serverStore.profiles.contains(where: { $0.id == profile.id })
    }

    var body: some View {
        NavigationStack {
            Form {
                connectionSection
                accountSection
                if profile.scheme == .https {
                    httpsSection
                }
                if let error {
                    Section {
                        Text(error)
                            .font(.nocCaption)
                            .foregroundStyle(.red)
                    }
                }
                actionSection
            }
            .navigationTitle(isEditingExisting ? "编辑服务器" : "添加服务器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                portText = String(profile.port)
                if isEditingExisting, let saved = serverStore.password(for: profile) {
                    password = saved
                }
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-password"), i + 1 < args.count {
                    password = args[i + 1]
                }
                if args.contains("-autoconnect") {
                    Task {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        await connectAndSave()
                    }
                }
                #endif
            }
        }
    }

    // MARK: 章节

    private var connectionSection: some View {
        Section {
            TextField("备注名（家里的 DS220+）", text: $profile.name)
                .textInputAutocapitalization(.never)
            Picker("协议", selection: $profile.scheme) {
                ForEach(ServerProfile.Scheme.allCases) { s in
                    Text(s.rawValue.uppercased()).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: profile.scheme) { _, newValue in
                // 用户未自定义过端口时跟随协议默认值
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
                        // 仅允许数字，落入 1-65535
                        let digits = new.filter(\.isNumber)
                        if digits != new { portText = digits }
                        if let v = Int(digits), v > 0, v <= 65535 { profile.port = v }
                    }
            }
        } header: {
            Text("连接")
        } footer: {
            Text("默认 HTTP 5000、HTTPS 5001；外网或自定义端口请改为实际值。")
        }
    }

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
                Button { passwordVisible.toggle() } label: {
                    Image(systemName: passwordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            TextField("二步验证码（可选）", text: $otp)
                .keyboardType(.numberPad)
            Toggle("记住密码", isOn: $rememberPassword)
        } header: {
            Text("账号")
        } footer: {
            Text("启用了二步验证（OTP）的账号需填入 6 位代码。密码加密存于 Keychain。")
        }
    }

    private var httpsSection: some View {
        Section {
            Toggle("信任自签名证书", isOn: $profile.ignoreInvalidCertificate)
        } footer: {
            Text("仅在你信任的局域网或私有 NAS 上开启。")
        }
    }

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
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .disabled(!canSubmit || isConnecting)

            if isEditingExisting {
                Button("仅保存配置（不立即登录）") { saveOnly() }
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: 行为

    private var canSubmit: Bool {
        !profile.host.trimmingCharacters(in: .whitespaces).isEmpty
            && !profile.username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && profile.port > 0 && profile.port <= 65535
    }

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
            // 成功：保存档案、密码（如选择）、激活、注入会话
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
            self.error = "需要双重验证：请在「二步验证码」字段输入 6 位代码后再试。"
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
