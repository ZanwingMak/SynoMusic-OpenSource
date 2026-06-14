import XCTest

/// 烟雾测试：启动 App 后看到品牌名。
final class SmokeTests: XCTestCase {

    func test_launchesAndShowsBrand() throws {
        let app = XCUIApplication()
        app.launch()
        let brand = app.staticTexts["SynoMusic"]
        XCTAssertTrue(brand.waitForExistence(timeout: 5))
    }
}
