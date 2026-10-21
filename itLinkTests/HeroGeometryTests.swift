import XCTest
@testable import itLink

final class HeroGeometryTests: XCTestCase {
    func testAspectFitLetterboxesWideImage() {
        let frame = HeroGeometry.aspectFitFrame(
            for: CGSize(width: 200, height: 100),
            in: CGRect(x: 0, y: 0, width: 100, height: 100)
        )

        XCTAssertEqual(frame.width, 100, accuracy: 0.01)
        XCTAssertEqual(frame.height, 50, accuracy: 0.01)
        XCTAssertEqual(frame.minX, 0, accuracy: 0.01)
        XCTAssertEqual(frame.minY, 25, accuracy: 0.01)
    }

    func testAspectFitLetterboxesTallImage() {
        let frame = HeroGeometry.aspectFitFrame(
            for: CGSize(width: 100, height: 200),
            in: CGRect(x: 10, y: 20, width: 100, height: 100)
        )

        XCTAssertEqual(frame.width, 50, accuracy: 0.01)
        XCTAssertEqual(frame.height, 100, accuracy: 0.01)
        XCTAssertEqual(frame.midX, 60, accuracy: 0.01)
        XCTAssertEqual(frame.midY, 70, accuracy: 0.01)
    }

    func testProgressClamps() {
        XCTAssertEqual(HeroGeometry.progress(for: -20, distance: 100), 0)
        XCTAssertEqual(HeroGeometry.progress(for: 40, distance: 100), 0.4, accuracy: 0.001)
        XCTAssertEqual(HeroGeometry.progress(for: 180, distance: 100), 1)
    }

    func testInteractiveFrameStartsAtFingerAndEndsAtCell() {
        let start = CGRect(x: 0, y: 0, width: 200, height: 400)
        let end = CGRect(x: 20, y: 20, width: 40, height: 40)

        let atRest = HeroGeometry.interactiveFrame(
            start: start,
            end: end,
            translation: .zero,
            progress: 0
        )
        XCTAssertEqual(atRest, start)

        let settled = HeroGeometry.interactiveFrame(
            start: start,
            end: end,
            translation: CGSize(width: 80, height: 120),
            progress: 1
        )
        XCTAssertEqual(settled.origin.x, end.origin.x, accuracy: 0.01)
        XCTAssertEqual(settled.origin.y, end.origin.y, accuracy: 0.01)
        XCTAssertEqual(settled.size.width, end.size.width, accuracy: 0.01)
        XCTAssertEqual(settled.size.height, end.size.height, accuracy: 0.01)
    }

    func testLerpRect() {
        let result = HeroGeometry.lerp(
            CGRect(x: 0, y: 0, width: 10, height: 10),
            CGRect(x: 10, y: 20, width: 30, height: 50),
            t: 0.5
        )
        XCTAssertEqual(result, CGRect(x: 5, y: 10, width: 20, height: 30))
    }
}
