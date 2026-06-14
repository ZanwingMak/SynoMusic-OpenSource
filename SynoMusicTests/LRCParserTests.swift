import XCTest
@testable import SynoMusic

final class LRCParserTests: XCTestCase {

    func test_parsesSimpleTimestamps() {
        let lrc = """
        [00:01.00]第一句
        [00:05.50]第二句
        [00:10]第三句
        """
        let lines = AudioStationAPI.parseLRC(lrc)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].text, "第一句")
        XCTAssertEqual(lines[0].timestamp, 1.0, accuracy: 0.01)
        XCTAssertEqual(lines[1].timestamp, 5.5, accuracy: 0.01)
        XCTAssertEqual(lines[2].timestamp, 10.0, accuracy: 0.01)
    }

    func test_emptyInputReturnsEmpty() {
        XCTAssertTrue(AudioStationAPI.parseLRC("").isEmpty)
    }

    func test_multipleStampsForSameLineProduceDuplicates() {
        // [00:01][00:30] 副歌：两条时间戳同一文本
        let lrc = "[00:01.00][00:30.00]副歌"
        let lines = AudioStationAPI.parseLRC(lrc)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines.first?.text, "副歌")
        XCTAssertEqual(lines.last?.text, "副歌")
        // 排序后 1.0 在前
        XCTAssertLessThan(lines[0].timestamp, lines[1].timestamp)
    }
}
