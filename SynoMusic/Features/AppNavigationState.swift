import SwiftUI

/// 主框架底部 Tab。
enum MainTab: Hashable {
    case library
    case browse
    case search
    case settings
}

/// 设置页可被外部直达的子页面。
enum SettingsRoute: Hashable {
    case downloads
    case login(ServerProfile)
}

/// App 内部导航状态：让全屏播放器等浮层可以请求切换 Tab 或进入设置子页。
@MainActor
final class AppNavigationState: ObservableObject {
    @Published var selectedTab: MainTab
    @Published var settingsPath = NavigationPath()

    /// 按调试启动参数决定初始 Tab，普通启动默认进入资料库。
    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-tab=browse") {
            selectedTab = .browse
        } else if args.contains("-tab=search") {
            selectedTab = .search
        } else if args.contains("-tab=settings") {
            selectedTab = .settings
        } else {
            selectedTab = .library
        }
        #else
        selectedTab = .library
        #endif
    }

    /// 切到设置页并打开下载管理。
    func openDownloads() {
        selectedTab = .settings
        settingsPath = NavigationPath()
        settingsPath.append(SettingsRoute.downloads)
    }

    /// 切到设置页并打开指定服务器的手动登录页。
    func openLogin(for profile: ServerProfile) {
        selectedTab = .settings
        settingsPath.append(SettingsRoute.login(profile))
    }
}
