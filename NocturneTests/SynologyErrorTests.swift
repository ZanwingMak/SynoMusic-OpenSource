import XCTest
@testable import Nocturne

final class SynologyErrorTests: XCTestCase {

    func test_authCode_mapsKnownCodes() {
        XCTAssertTrue(SynologyError.describe(authCode: 400).contains("账号或密码"))
        XCTAssertTrue(SynologyError.describe(authCode: 403).contains("OTP"))
        XCTAssertTrue(SynologyError.describe(authCode: 405).contains("锁定"))
    }

    func test_authCode_fallsBackForUnknown() {
        XCTAssertTrue(SynologyError.describe(authCode: 9999).contains("9999"))
    }

    func test_commonCode_mapsSessionFailures() {
        XCTAssertTrue(SynologyError.describe(commonCode: 106).contains("会话超时"))
        XCTAssertTrue(SynologyError.describe(commonCode: 119).contains("SID"))
    }
}
