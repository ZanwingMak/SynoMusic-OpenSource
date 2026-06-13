import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// 单例 class 持有 ActivityKit 句柄。
/// 用 `@unchecked Sendable` + NSLock 自管线程安全，规避 actor / @MainActor 上下文
/// 跨边界传递 Activity / ActivityContent 时 Swift 6 严格并发的 sending 检查。
/// 调用方只需传入 Sendable 的 ContentState，本类内部 await ActivityKit 异步方法。
@available(iOS 16.2, *)
final class LiveActivityCoordinator: @unchecked Sendable {
    static let shared = LiveActivityCoordinator()

    private let lock = NSLock()
    private var current: Activity<NowPlayingActivityAttributes>?

    private func snapshot() -> Activity<NowPlayingActivityAttributes>? {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    private func store(_ activity: Activity<NowPlayingActivityAttributes>?) {
        lock.lock(); current = activity; lock.unlock()
    }

    /// 启动或更新 Live Activity。
    func updateOrStart(_ state: NowPlayingActivityAttributes.ContentState) async {
        let content = ActivityContent(state: state, staleDate: nil)
        if let existing = snapshot() {
            await existing.update(content)
            return
        }
        let attrs = NowPlayingActivityAttributes(sessionStartedAt: Date())
        do {
            let new = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: nil
            )
            store(new)
        } catch {
            // 用户未启用 Live Activity / iOS < 16.2 / 系统拒绝，静默处理
        }
    }

    /// 结束并清理 Live Activity 句柄。
    func endActivity() async {
        guard let existing = snapshot() else { return }
        store(nil)
        await existing.end(nil, dismissalPolicy: .immediate)
    }
}
#endif
