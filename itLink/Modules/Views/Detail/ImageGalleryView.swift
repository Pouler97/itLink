import SwiftUI

struct ImageGalleryView: View {
    let cellFrames: [String: CGRect]
    let sourceFrame: CGRect
    let previewImage: UIImage?
    let onHeroItemChange: (String?) -> Void
    let onClose: () -> Void

    @State private var viewModel: ImageGalleryViewModel
    @State private var selectedItemID: String
    @State private var phase: GalleryHeroPhase = .opening
    @State private var dragTranslation: CGSize = .zero
    @State private var heroFrame: CGRect
    @State private var heroRadius: CGFloat = HeroGeometry.cellCornerRadius
    @State private var dimOpacity: CGFloat = 0
    @State private var canvasFrame: CGRect = .zero
    @State private var lockedHeroImage: UIImage?
    @State private var pagerVisible = false

    init(
        items: [ImageGridItem],
        startIndex: Int,
        cellFrames: [String: CGRect],
        sourceFrame: CGRect,
        previewImage: UIImage?,
        onHeroItemChange: @escaping (String?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.cellFrames = cellFrames
        self.sourceFrame = sourceFrame
        self.previewImage = previewImage
        self.onHeroItemChange = onHeroItemChange
        self.onClose = onClose
        let clampedStart = min(max(startIndex, 0), max(items.count - 1, 0))
        let startItemID = items.indices.contains(clampedStart) ? items[clampedStart].id : ""
        _viewModel = State(initialValue: ImageGalleryViewModel(items: items, startIndex: clampedStart))
        _selectedItemID = State(initialValue: startItemID)
        _heroFrame = State(initialValue: sourceFrame)
        _lockedHeroImage = State(initialValue: previewImage)
    }

    private var currentItem: ImageGridItem? {
        viewModel.pageItems.first(where: { $0.id == selectedItemID }) ?? viewModel.currentItem
    }

    private var currentItemID: String? {
        currentItem?.id
    }

    private var heroImage: UIImage? {
        if let lockedHeroImage {
            return lockedHeroImage
        }
        if let item = currentItem, let image = viewModel.image(for: item) {
            return image
        }
        return previewImage
    }

    private var isChromeShown: Bool {
        GalleryHeroLayout.isChromeShown(
            phase: phase,
            pagerVisible: pagerVisible,
            isChromeVisible: viewModel.isChromeVisible,
            dragHeight: dragTranslation.height
        )
    }

    private var showsHero: Bool {
        GalleryHeroLayout.showsHero(
            phase: phase,
            pagerVisible: pagerVisible,
            dragHeight: dragTranslation.height
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let canvas = proxy.frame(in: .global)
            photoLayer(canvas: canvas)
                .onAppear {
                    canvasFrame = canvas
                    viewModel.onAppear()
                    startOpenTransition(in: canvas)
                }
                .onChange(of: canvas) { _, newCanvas in
                    canvasFrame = newCanvas
                }
        }
        .ignoresSafeArea()
        .overlay {
            GalleryChrome(
                items: viewModel.pageItems,
                thumbnails: viewModel.thumbnails,
                currentItemID: currentItemID,
                shareURL: viewModel.currentURL,
                isShown: isChromeShown,
                onBack: closeToCell,
                onSelect: { item in
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedItemID = item.id
                    }
                }
            )
        }
        .onDisappear {
            viewModel.cancelAllLoading()
        }
        .onChange(of: selectedItemID) { _, newID in
            if let index = viewModel.index(of: newID) {
                viewModel.selectIndex(index)
            }
        }
    }

    private func photoLayer(canvas: CGRect) -> some View {
        let displayedHeroFrame = resolvedHeroFrame(in: canvas)
        let displayedRadius = GalleryHeroLayout.resolvedHeroRadius(
            phase: phase,
            heroRadius: heroRadius,
            dragHeight: dragTranslation.height
        )
        let displayedDim = GalleryHeroLayout.resolvedDimOpacity(
            phase: phase,
            dimOpacity: dimOpacity,
            dragHeight: dragTranslation.height
        )

        return ZStack {
            Color.black
                .opacity(displayedDim)
                .ignoresSafeArea()
                .allowsHitTesting(phase == .settled && dragTranslation.height < 8)

            GalleryPager(
                items: viewModel.pageItems,
                selectedItemID: $selectedItemID,
                stateForItem: viewModel.state(for:),
                imageForItem: viewModel.image(for:),
                isInteractive: pagerVisible && !showsHero,
                onToggleChrome: { viewModel.toggleChrome() },
                onRetry: { viewModel.retry(item: $0) },
                onDismissChanged: handleDragChanged,
                onDismissEnded: handleDismissEnded
            )

            if showsHero, let image = heroImage, displayedHeroFrame.width > 1 {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: displayedHeroFrame.width, height: displayedHeroFrame.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: displayedRadius, style: .continuous))
                    .position(
                        x: displayedHeroFrame.midX - canvas.minX,
                        y: displayedHeroFrame.midY - canvas.minY
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    private func resolvedHeroFrame(in canvas: CGRect) -> CGRect {
        GalleryHeroLayout.resolvedHeroFrame(
            phase: phase,
            heroFrame: heroFrame,
            dragTranslation: dragTranslation,
            canvas: canvas,
            sourceFrame: sourceFrame,
            cellFrames: cellFrames,
            currentItemID: currentItemID,
            imageSize: heroImage?.size
        )
    }

    private func startOpenTransition(in canvas: CGRect) {
        canvasFrame = canvas
        lockedHeroImage = previewImage ?? currentItem.flatMap(viewModel.image(for:))
        onHeroItemChange(currentItemID)

        let startFrame = GalleryHeroLayout.sourceFrame(
            sourceFrame: sourceFrame,
            cellFrames: cellFrames,
            currentItemID: currentItemID,
            canvas: canvas
        )
        let endFrame = GalleryHeroLayout.fullscreenFrame(imageSize: heroImage?.size, canvas: canvas)
        heroFrame = startFrame
        heroRadius = HeroGeometry.cellCornerRadius
        dimOpacity = 0
        pagerVisible = false
        phase = .opening

        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                heroFrame = endFrame
                heroRadius = 0
                dimOpacity = 1
            } completion: {
                guard phase == .opening else { return }
                pagerVisible = true
                phase = .settled
                lockedHeroImage = nil
            }
        }
    }

    private func handleDragChanged(_ translation: CGSize) {
        let clamped = CGSize(width: translation.width, height: max(0, translation.height))
        if phase == .settled {
            lockedHeroImage = heroImage
            pagerVisible = false
            phase = .dragging
            onHeroItemChange(currentItemID)
        }
        guard phase == .dragging else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragTranslation = clamped
        }
    }

    private func handleDismissEnded(_ shouldDismiss: Bool) {
        guard phase == .dragging else { return }
        if shouldDismiss {
            closeToCell()
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                dragTranslation = .zero
            } completion: {
                guard phase == .dragging else { return }
                pagerVisible = true
                phase = .settled
                lockedHeroImage = nil
            }
        }
    }

    private func closeToCell() {
        let canvas = canvasFrame
        let currentFrame = resolvedHeroFrame(in: canvas)
        let currentRadius = GalleryHeroLayout.resolvedHeroRadius(
            phase: phase,
            heroRadius: heroRadius,
            dragHeight: dragTranslation.height
        )
        let currentDim = GalleryHeroLayout.resolvedDimOpacity(
            phase: phase,
            dimOpacity: dimOpacity,
            dragHeight: dragTranslation.height
        )
        let endFrame = GalleryHeroLayout.targetCellFrame(
            sourceFrame: sourceFrame,
            cellFrames: cellFrames,
            currentItemID: currentItemID,
            canvas: canvas
        )

        lockedHeroImage = heroImage
        onHeroItemChange(currentItemID)
        pagerVisible = false
        heroFrame = currentFrame
        heroRadius = currentRadius
        dimOpacity = currentDim
        phase = .closing
        dragTranslation = .zero

        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
            heroFrame = endFrame
            heroRadius = HeroGeometry.cellCornerRadius
            dimOpacity = 0
        } completion: {
            onClose()
        }
    }
}
