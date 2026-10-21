import XCTest
@testable import itLink

final class GridLayoutCalculatorTests: XCTestCase {
    func testColumnCountNeverLessThanOne() {
        XCTAssertEqual(GridLayoutCalculator.columnCount(for: 50), 1)
        XCTAssertEqual(GridLayoutCalculator.columnCount(for: 0), 1)
    }

    func testCellSizeStaysWithinSpecWhenWidthAllows() {
        let widths: [CGFloat] = [320, 375, 390, 393, 430, 744, 768, 834, 1024, 1366]

        for width in widths {
            let layout = GridLayoutCalculator.layout(for: width)
            XCTAssertGreaterThanOrEqual(layout.columnCount, 1, "width \(width)")
            XCTAssertGreaterThanOrEqual(layout.cellSize, GridLayoutCalculator.minCellWidth, "width \(width)")
            XCTAssertLessThanOrEqual(layout.cellSize, GridLayoutCalculator.maxCellWidth, "width \(width)")
        }
    }

    func testCappedCellLeavesExtraSpaceInsteadOfExceedingMax() {
        let layout = GridLayoutCalculator.layout(for: 430)
        XCTAssertEqual(layout.cellSize, GridLayoutCalculator.maxCellWidth)
        XCTAssertEqual(layout.columnCount, 3)
    }

    func testCellSizeAccountsForPaddingAndSpacing() {
        let width: CGFloat = 390
        let layout = GridLayoutCalculator.layout(for: width)
        let usedWidth = layout.cellSize * CGFloat(layout.columnCount)
            + layout.spacing * CGFloat(layout.columnCount - 1)
            + layout.padding * 2

        XCTAssertLessThanOrEqual(usedWidth, width + 0.01)
        XCTAssertEqual(layout.columnCount, 3)
        XCTAssertEqual(layout.cellSize, 119.333, accuracy: 0.01)
    }
}
