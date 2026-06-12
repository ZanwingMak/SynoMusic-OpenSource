import XCTest
@testable import Nocturne

@MainActor
final class PlaybackQueueTests: XCTestCase {

    private func makeSong(_ id: String) -> Song {
        Song(id: id, title: id, album: nil, artist: nil, albumArtist: nil,
             genre: nil, composer: nil, trackNumber: nil, discNumber: nil, year: nil,
             duration: 0, bitrate: nil, codec: nil, filesize: nil, path: nil, rating: nil)
    }

    func test_removeFromQueue_adjustsIndices() {
        let engine = PlaybackEngine()
        let songs = (0..<5).map { makeSong("s\($0)") }
        // 模拟队列状态：直接通过 play 进入。
        engine.play(queue: songs, startAt: 2)
        // 移除前置项：currentIndex 应减 1
        engine.removeFromQueue(at: 0)
        XCTAssertEqual(engine.currentSong?.id, "s2")
    }

    func test_appendNext_insertsRightAfterCurrent() {
        let engine = PlaybackEngine()
        let initial = (0..<3).map { makeSong("s\($0)") }
        engine.play(queue: initial, startAt: 0)
        engine.appendNext(makeSong("inserted"))
        // 队列中位置 1 应为新插入项
        XCTAssertEqual(engine.queue[1].id, "inserted")
    }

    func test_cycleRepeatMode_rotatesThroughStates() {
        let engine = PlaybackEngine()
        XCTAssertEqual(engine.repeatMode, .off)
        engine.cycleRepeatMode(); XCTAssertEqual(engine.repeatMode, .all)
        engine.cycleRepeatMode(); XCTAssertEqual(engine.repeatMode, .one)
        engine.cycleRepeatMode(); XCTAssertEqual(engine.repeatMode, .off)
    }
}
