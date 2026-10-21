import Foundation

enum GridSizeProfile: Equatable {
    case compact
    case regular
}

enum GridLayoutCalculator {
    static let minCellWidth: CGFloat = Metrics.compact.minCellWidth
    static let maxCellWidth: CGFloat = Metrics.compact.maxCellWidth

    struct Metrics: Equatable {
        let minCellWidth: CGFloat
        let maxCellWidth: CGFloat
        let spacing: CGFloat
        let padding: CGFloat

        static let compact = Metrics(
            minCellWidth: 100,
            maxCellWidth: 120,
            spacing: 8,
            padding: 8
        )

        static let regular = Metrics(
            minCellWidth: 168,
            maxCellWidth: 210,
            spacing: 12,
            padding: 16
        )
    }

    struct Layout: Equatable {
        let columnCount: Int
        let cellSize: CGFloat
        let spacing: CGFloat
        let padding: CGFloat
    }

    static func metrics(for profile: GridSizeProfile) -> Metrics {
        switch profile {
        case .compact:
            return .compact
        case .regular:
            return .regular
        }
    }

    static func layout(for containerWidth: CGFloat, profile: GridSizeProfile = .compact) -> Layout {
        let metrics = metrics(for: profile)
        let availableWidth = max(0, containerWidth - metrics.padding * 2)
        let columnCount = columnCount(forAvailableWidth: availableWidth, metrics: metrics)
        let cellSize = cellSize(
            forAvailableWidth: availableWidth,
            columnCount: columnCount,
            metrics: metrics
        )
        return Layout(
            columnCount: columnCount,
            cellSize: cellSize,
            spacing: metrics.spacing,
            padding: metrics.padding
        )
    }

    static func columnCount(forAvailableWidth width: CGFloat, metrics: Metrics = .compact) -> Int {
        max(1, Int(floor((width + metrics.spacing) / (metrics.minCellWidth + metrics.spacing))))
    }

    static func cellSize(
        forAvailableWidth width: CGFloat,
        columnCount: Int,
        metrics: Metrics = .compact
    ) -> CGFloat {
        let columns = max(columnCount, 1)
        let rawSize = (width - metrics.spacing * CGFloat(columns - 1)) / CGFloat(columns)
        return min(metrics.maxCellWidth, max(0, rawSize))
    }

    static func columnCount(for width: CGFloat) -> Int {
        layout(for: width).columnCount
    }
}
