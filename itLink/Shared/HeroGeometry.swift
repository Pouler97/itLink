import CoreGraphics
import Foundation
import SwiftUI

struct GalleryCellFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

enum HeroGeometry {
    static let cellCornerRadius: CGFloat = 8
    static let dismissDistance: CGFloat = 520

    static func aspectFitFrame(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    static func lerp(_ a: CGRect, _ b: CGRect, t: CGFloat) -> CGRect {
        CGRect(
            x: lerp(a.origin.x, b.origin.x, t: t),
            y: lerp(a.origin.y, b.origin.y, t: t),
            width: lerp(a.width, b.width, t: t),
            height: lerp(a.height, b.height, t: t)
        )
    }

    static func progress(for translationY: CGFloat, distance: CGFloat = dismissDistance) -> CGFloat {
        min(1, max(0, translationY / distance))
    }

    /// Follow the finger, shrink, and gradually pull toward the grid cell.
    static func interactiveFrame(
        start: CGRect,
        end: CGRect,
        translation: CGSize,
        progress: CGFloat
    ) -> CGRect {
        let t = min(1, max(0, progress))
        let pull = t * t
        let size = CGSize(
            width: lerp(start.width, end.width, t: t),
            height: lerp(start.height, end.height, t: t)
        )
        let fingerCenter = CGPoint(
            x: start.midX + translation.width,
            y: start.midY + translation.height
        )
        let center = CGPoint(
            x: lerp(fingerCenter.x, end.midX, t: pull),
            y: lerp(fingerCenter.y, end.midY, t: pull)
        )
        return CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func fallbackCellFrame(in canvas: CGRect) -> CGRect {
        let side = min(110, max(72, canvas.width * 0.24))
        return CGRect(
            x: canvas.midX - side / 2,
            y: canvas.minY + canvas.height * 0.16,
            width: side,
            height: side
        )
    }
}
