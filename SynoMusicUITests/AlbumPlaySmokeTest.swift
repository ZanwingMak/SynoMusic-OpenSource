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

    /// 让 NowPlaying artwork 闭包真正被 MediaPlayer 在 accessQueue 上回调一次：
    /// 后台短切回前台，模拟系统读取锁屏元数据。回归 attachArtwork 隔离崩溃。
    func test_nowPlayingArtworkHandlerSurvivesBackgrounding() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-fullplayer"]
        app.launch()
        XCTAssertTrue(app.staticTexts["正在播放"].waitForExistence(timeout: 5))

        // 触发后台 + 回前台，让锁屏 / 控制中心读 NowPlaying。
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1.5)
        app.activate()
        Thread.sleep(forTimeInterval: 1.5)

        // 关键是进程没死：notRunning 表示崩溃；其它状态都说明 artwork 闭包未触发 SIGTRAP。
        XCTAssertNotEqual(app.state, .notRunning, "进程崩溃了（artwork 闭包又被 trap）")
    }
}
