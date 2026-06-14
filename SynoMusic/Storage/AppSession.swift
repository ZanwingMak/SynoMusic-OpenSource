import Foundation

/// 应用会话：保存当前已登录的 SynologyClient。
/// 退出/切换服务器时会被替换。
@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var client: SynologyClient?

    var isLoggedIn: Bool { client != nil }

    /// 注入已登录客户端。
    func sign(in client: SynologyClient) {
        self.client = client
    }

    /// 注销并丢弃客户端。
    func signOut() async {
        await client?.logout()
        client = nil
    }
}
