import SwiftUI

/// 服务器档案编辑：新增或编辑 NAS 连接信息。
struct ServerEditorView: View {
    @EnvironmentObject private var serverStore: ServerStore
    @Environment(\.dismiss) private var dismiss

    @State var profile: ServerProfile

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("备注名（如：家里的 DS220+）", text: $profile.name)
                        .textInputAutocapitalization(.never)
                    HStack {
                        Picker("协议", selection: $profile.scheme) {
                            ForEach(ServerProfile.Scheme.allCases) { s in
                                Text(s.rawValue.uppercased()).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    TextField("主机或 QuickConnect ID", text: $profile.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)
                    Stepper(value: $profile.port, in: 1...65535) {
                        HStack {
                            Text("端口")
                            Spacer()
                            Text("\(profile.port)").foregroundStyle(.secondary)
                        }
                    }
                }
                Section("账号") {
                    TextField("用户名", text: $profile.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                if profile.scheme == .https {
                    Section {
                        Toggle("信任自签名证书", isOn: $profile.ignoreInvalidCertificate)
                    } footer: {
                        Text("仅在你信任的局域网 NAS 上开启。")
                    }
                }
                Section {
                    Button {
                        save()
                    } label: {
                        Text("保存")
                    }
                    .disabled(profile.host.isEmpty || profile.username.isEmpty)
                }
            }
            .navigationTitle("服务器配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }

    private func save() {
        var p = profile
        if p.name.trimmingCharacters(in: .whitespaces).isEmpty {
            p.name = p.host
        }
        serverStore.upsert(p)
        Haptics.success()
        dismiss()
    }
}
