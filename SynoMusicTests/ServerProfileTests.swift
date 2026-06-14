import XCTest
@testable import SynoMusic

final class ServerProfileTests: XCTestCase {

    func test_baseURL_includesPort() {
        let p = ServerProfile(name: "DS", scheme: .http, host: "192.168.1.10", port: 5000, username: "u")
        XCTAssertEqual(p.baseURL?.absoluteString, "http://192.168.1.10:5000")
    }

    func test_displayURL_isReadable() {
        let p = ServerProfile(name: "DS", scheme: .https, host: "nas.local", port: 5001, username: "u")
        XCTAssertEqual(p.displayURL, "https://nas.local:5001")
    }

    func test_defaultName_fallsBackToHost() {
        let p = ServerProfile(host: "10.0.0.5", username: "u")
        XCTAssertEqual(p.name, "10.0.0.5")
    }
}
