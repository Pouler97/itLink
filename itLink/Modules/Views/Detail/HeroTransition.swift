import CoreGraphics

enum GalleryHeroPhase {
    case opening
    case settled
    case dragging
    case closing
}

enum GalleryHeroLayout {
    static func isChromeShown(
        phase: GalleryHeroPhase,
        pagerVisible: Bool,
        isChromeVisible: Bool,
        dragHeight: CGFloat
    ) -> Bool {
        phase == .settled && pagerVisible && isChromeVisible && dragHeight < 8
    }

    static func showsHero(
        phase: GalleryHeroPhase,
        pagerVisible: Bool,
        dragHeight: CGFloat
    ) -> Bool {
        !pagerVisible || phase != .settled || dragHeight > 0
    }

    static func sourceFrame(
        sourceFrame: CGRect,
        cellFrames: [String: CGRect],
        currentItemID: String?,
        canvas: CGRect
    ) -> CGRect {
        if sourceFrame.width > 1, sourceFrame.height > 1 {
            return sourceFrame
        }
        if let currentItemID, let frame = cellFrames[currentItemID], frame.width > 1, frame.height > 1 {
            return frame
        }
        return HeroGeometry.fallbackCellFrame(in: canvas)
    }

    static func targetCellFrame(
        sourceFrame: CGRect,
        cellFrames: [String: CGRect],
        currentItemID: String?,
        canvas: CGRect
    ) -> CGRect {
        if let currentItemID, let frame = cellFrames[currentItemID], frame.width > 1, frame.height > 1 {
            return frame
        }
        if sourceFrame.width > 1 {
            return sourceFrame
        }
        return HeroGeometry.fallbackCellFrame(in: canvas)
    }

    static func fullscreenFrame(imageSize: CGSize?, canvas: CGRect) -> CGRect {
        if let imageSize {
            return HeroGeometry.aspectFitFrame(for: imageSize, in: canvas)
        }
        return canvas
    }

    static func resolvedHeroFrame(
        phase: GalleryHeroPhase,
        heroFrame: CGRect,
        dragTranslation: CGSize,
        canvas: CGRect,
        sourceFrame: CGRect,
        cellFrames: [String: CGRect],
        currentItemID: String?,
        imageSize: CGSize?
    ) -> CGRect {
        switch phase {
        case .dragging:
            return HeroGeometry.interactiveFrame(
                start: fullscreenFrame(imageSize: imageSize, canvas: canvas),
                end: targetCellFrame(
                    sourceFrame: sourceFrame,
                    cellFrames: cellFrames,
                    currentItemID: currentItemID,
                    canvas: canvas
                ),
                translation: dragTranslation,
                progress: HeroGeometry.progress(for: dragTranslation.height)
            )
        case .opening, .closing:
            return heroFrame.width > 1
                ? heroFrame
                : self.sourceFrame(
                    sourceFrame: sourceFrame,
                    cellFrames: cellFrames,
                    currentItemID: currentItemID,
                    canvas: canvas
                )
        case .settled:
            return fullscreenFrame(imageSize: imageSize, canvas: canvas)
        }
    }

    static func resolvedHeroRadius(phase: GalleryHeroPhase, heroRadius: CGFloat, dragHeight: CGFloat) -> CGFloat {
        switch phase {
        case .dragging:
            return HeroGeometry.lerp(0, HeroGeometry.cellCornerRadius, t: HeroGeometry.progress(for: dragHeight))
        case .opening, .closing:
            return heroRadius
        case .settled:
            return 0
        }
    }

    static func resolvedDimOpacity(phase: GalleryHeroPhase, dimOpacity: CGFloat, dragHeight: CGFloat) -> CGFloat {
        switch phase {
        case .dragging:
            return max(0, 1 - HeroGeometry.progress(for: dragHeight))
        case .opening, .closing, .settled:
            return dimOpacity
        }
    }
}
