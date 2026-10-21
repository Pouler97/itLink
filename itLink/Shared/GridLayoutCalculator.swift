import Foundation

enum GridLayoutCalculator {
    static let minCellWidth: CGFloat = 100
    static let maxCellWidth: CGFloat = 120
    static let targetCellWidth: CGFloat = 110
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 8

    struct Layout: Equatable {
        let columnCount: Int
        let cellSize: CGFloat
        let spacing: CGFloat
        let padding: CGFloat
    }

    static func layout(for containerWidth: CGFloat) -> Layout {
        let availableWidth = max(0, containerWidth - padding * 2)
        let columnCount = columnCount(forAvailableWidth: availableWidth)
        let cellSize = cellSize(forAvailableWidth: availableWidth, columnCount: columnCount)
        return Layout(
            columnCount: columnCount,
            cellSize: cellSize,
            spacing: spacing,
            padding: padding
        )
    }

    /// Matches `GridItem(.adaptive(minimum: 100, maximum: 120))`.
    static func columnCount(forAvailableWidth width: CGFloat) -> Int {
        max(1, Int(floor((width + spacing) / (minCellWidth + spacing))))
    }

    static func cellSize(forAvailableWidth width: CGFloat, columnCount: Int) -> CGFloat {
        let columns = max(columnCount, 1)
        let rawSize = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        return min(maxCellWidth, max(0, rawSize))
    }

    static func columnCount(for width: CGFloat) -> Int {
        layout(for: width).columnCount
    }

    static func cellSize(for width: CGFloat, columnCount: Int) -> CGFloat {
        let availableWidth = max(0, width - padding * 2)
        return cellSize(forAvailableWidth: availableWidth, columnCount: columnCount)
    }
}
