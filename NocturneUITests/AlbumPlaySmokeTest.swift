import XCTest

/// 触发"点击专辑 → 点击播放按钮"路径，验证不再像 KVO 那次一样直接闪退。
/// 用 `-demo -fullplayer` 路径在没有真 NAS 的前提下也能跑：
/// app 启动后会 demo 模式注入歌曲并自动弹全屏播放器，立即触发整条播放管道。
final class AlbumPlaySmokeTest: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// 仅启动 + 弹全屏播放器；如果 KVO/隔离链路有问题，会在前 5 秒内 SIGTRAP。
    func test_fullPlayerLaunchDoesNotCrash() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-fullplayer"]
        app.launch()

        // 等播放器视图出来；3 秒内出不来认为是回归。
        let playerHeader = app.staticTexts["正在播放"]
        XCTAssertTrue(playerHeader.waitForExistence(timeout: 5))
        // 让 KVO/timeObserver 跑 2 秒再退出。
        Thread.sleep(forTimeInterval: 2.0)
        // 仍在运行则进程态为 runningForeground。
        XCTAssertEqual(app.state, .runningForeground)
    }
}
