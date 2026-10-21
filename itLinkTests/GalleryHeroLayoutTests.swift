import XCTest
@testable import itLink

final class GalleryHeroLayoutTests: XCTestCase {
    func testChromeShownOnlyWhenSettledAndPagerVisible() {
        XCTAssertTrue(
            GalleryHeroLayout.isChromeShown(
                phase: .settled,
                pagerVisible: true,
                isChromeVisible: true,
                dragHeight: 0
            )
        )
        XCTAssertFalse(
            GalleryHeroLayout.isChromeShown(
                phase: .settled,
                pagerVisible: true,
                isChromeVisible: true,
                dragHeight: 12
            )
        )
        XCTAssertFalse(
            GalleryHeroLayout.isChromeShown(
                phase: .dragging,
                pagerVisible: true,
                isChromeVisible: true,
                dragHeight: 0
            )
        )
    }

    func testShowsHeroDuringOpenAndDrag() {
        XCTAssertTrue(
            GalleryHeroLayout.showsHero(phase: .opening, pagerVisible: false, dragHeight: 0)
        )
        XCTAssertTrue(
            GalleryHeroLayout.showsHero(phase: .settled, pagerVisible: true, dragHeight: 20)
        )
        XCTAssertFalse(
            GalleryHeroLayout.showsHero(phase: .settled, pagerVisible: true, dragHeight: 0)
        )
    }

    func testTargetCellFramePrefersCurrentItemFrame() {
        let canvas = CGRect(x: 0, y: 0, width: 400, height: 800)
        let source = CGRect(x: 10, y: 10, width: 80, height: 80)
        let current = CGRect(x: 200, y: 400, width: 100, height: 100)

        let frame = GalleryHeroLayout.targetCellFrame(
            sourceFrame: source,
            cellFrames: ["b": current],
            currentItemID: "b",
            canvas: canvas
        )

        XCTAssertEqual(frame, current)
    }

    func testSettledHeroFrameUsesAspectFit() {
        let canvas = CGRect(x: 0, y: 0, width: 100, height: 100)
        let frame = GalleryHeroLayout.resolvedHeroFrame(
            phase: .settled,
            heroFrame: .zero,
            dragTranslation: .zero,
            canvas: canvas,
            sourceFrame: CGRect(x: 0, y: 0, width: 40, height: 40),
            cellFrames: [:],
            currentItemID: nil,
            imageSize: CGSize(width: 200, height: 100)
        )

        XCTAssertEqual(frame.width, 100, accuracy: 0.01)
        XCTAssertEqual(frame.height, 50, accuracy: 0.01)
    }
}
