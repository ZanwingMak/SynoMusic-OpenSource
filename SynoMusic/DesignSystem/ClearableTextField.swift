import SwiftUI

/// 带末尾 X 清除按钮的 TextField；输入非空时显示按钮，点击清空。
struct ClearableTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .never
    var autocorrect: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(!autocorrect)
            if !text.isEmpty {
                Button {
                    Haptics.tap()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除".t)
            }
        }
    }
}

/// 末尾 X 清除按钮的 SecureField 版本。
struct ClearableSecureField: View {
    let title: String
    @Binding var text: String
    @State private var visible: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Group {
                if visible {
                    TextField(title, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } else {
                    SecureField(title, text: $text)
                }
            }
            .textContentType(.oneTimeCode)

            if !text.isEmpty {
                Button {
                    Haptics.tap()
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("清除".t)
            }
            Button {
                visible.toggle()
            } label: {
                Image(systemName: visible ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
