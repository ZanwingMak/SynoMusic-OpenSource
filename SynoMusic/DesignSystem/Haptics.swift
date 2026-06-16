import UIKit

/// 触感反馈封装：保证调用方使用最克制的反馈强度。
enum Haptics {
    /// 轻点：列表选中、切换 Tab。
    @MainActor
    static func tap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// 软冲击：播放/暂停、点赞。
    @MainActor
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// 成功通知：下载完成、保存成功。
    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 失败通知：网络错误、登录失败。
    @MainActor
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
