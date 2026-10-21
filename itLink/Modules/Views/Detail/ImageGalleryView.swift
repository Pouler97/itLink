import SwiftUI
import UIKit

private enum GalleryHeroPhase {
    case opening
    case settled
    case dragging
    case closing
}

private enum GalleryChromeLayout {
    static let topOverlap: CGFloat = 52
    static let bottomOverlap: CGFloat = 22
    static let minimumPadding: CGFloat = 2
}

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

    private var dragProgress: CGFloat {
        HeroGeometry.progress(for: dragTranslation.height)
    }

    private var isChromeShown: Bool {
        phase == .settled && pagerVisible && viewModel.isChromeVisible && dragTranslation.height < 8
    }

    private var showsHero: Bool {
        !pagerVisible || phase != .settled || dragTranslation.height > 0
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
            chromeLayer
                .opacity(isChromeShown ? 1 : 0)
                .allowsHitTesting(isChromeShown)
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
        let displayedRadius = resolvedHeroRadius()
        let displayedDim = resolvedDimOpacity()

        return ZStack {
            Color.black
                .opacity(displayedDim)
                .ignoresSafeArea()
                .allowsHitTesting(phase == .settled && dragTranslation.height < 8)

            TabView(selection: $selectedItemID) {
                ForEach(viewModel.pageItems) { item in
                    GalleryPageContent(
                        item: item,
                        state: viewModel.state(for: item),
                        image: viewModel.image(for: item),
                        onToggleChrome: { viewModel.toggleChrome() },
                        onRetry: { viewModel.retry(item: item) },
                        onDismissChanged: handleDragChanged,
                        onDismissEnded: handleDismissEnded
                    )
                    .equatable()
                    .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(GalleryPageBackgroundClearer())
            .opacity(pagerVisible && !showsHero ? 1 : 0)
            .allowsHitTesting(pagerVisible && !showsHero)
            .ignoresSafeArea()

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

    private var chromeLayer: some View {
        let insets = WindowSafeArea.insets
        return VStack(spacing: 0) {
            galleryTopBar
            Spacer(minLength: 0)
            GalleryFilmstrip(
                items: viewModel.pageItems,
                thumbnails: viewModel.thumbnails,
                currentItemID: currentItemID,
                onSelect: { item in
                    selectedItemID = item.id
                }
            )
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 0)
        }
        .padding(.top, max(GalleryChromeLayout.minimumPadding, insets.top - GalleryChromeLayout.topOverlap))
        .padding(.bottom, max(GalleryChromeLayout.minimumPadding, insets.bottom - GalleryChromeLayout.bottomOverlap))
    }

    private var galleryTopBar: some View {
        HStack {
            GlassIconButton(
                systemName: "chevron.left",
                accessibilityLabel: "Назад",
                action: closeToCell
            )

            Spacer()

            shareMenu
        }
        .padding(.horizontal, 16)
    }

    private func fullscreenFrame(in canvas: CGRect) -> CGRect {
        if let image = heroImage {
            return HeroGeometry.aspectFitFrame(for: image.size, in: canvas)
        }
        return canvas
    }

    private func resolvedSourceFrame(in canvas: CGRect) -> CGRect {
        if sourceFrame.width > 1, sourceFrame.height > 1 {
            return sourceFrame
        }
        if let currentItemID, let frame = cellFrames[currentItemID], frame.width > 1, frame.height > 1 {
            return frame
        }
        return HeroGeometry.fallbackCellFrame(in: canvas)
    }

    private func targetCellFrame(in canvas: CGRect) -> CGRect {
        if let currentItemID, let frame = cellFrames[currentItemID], frame.width > 1, frame.height > 1 {
            return frame
        }
        if sourceFrame.width > 1 {
            return sourceFrame
        }
        return HeroGeometry.fallbackCellFrame(in: canvas)
    }

    private func resolvedHeroFrame(in canvas: CGRect) -> CGRect {
        switch phase {
        case .dragging:
            return HeroGeometry.interactiveFrame(
                start: fullscreenFrame(in: canvas),
                end: targetCellFrame(in: canvas),
                translation: dragTranslation,
                progress: dragProgress
            )
        case .opening, .closing:
            return heroFrame.width > 1 ? heroFrame : resolvedSourceFrame(in: canvas)
        case .settled:
            return fullscreenFrame(in: canvas)
        }
    }

    private func resolvedHeroRadius() -> CGFloat {
        switch phase {
        case .dragging:
            return HeroGeometry.lerp(0, HeroGeometry.cellCornerRadius, t: dragProgress)
        case .opening, .closing:
            return heroRadius
        case .settled:
            return 0
        }
    }

    private func resolvedDimOpacity() -> CGFloat {
        switch phase {
        case .dragging:
            return max(0, 1 - dragProgress)
        case .opening, .closing, .settled:
            return dimOpacity
        }
    }

    private func startOpenTransition(in canvas: CGRect) {
        canvasFrame = canvas
        lockedHeroImage = previewImage ?? currentItem.flatMap(viewModel.image(for:))
        onHeroItemChange(currentItemID)

        let startFrame = resolvedSourceFrame(in: canvas)
        let endFrame = fullscreenFrame(in: canvas)
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
        let currentRadius = resolvedHeroRadius()
        let currentDim = resolvedDimOpacity()
        let endFrame = targetCellFrame(in: canvas)

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

    @ViewBuilder
    private var shareMenu: some View {
        if let url = viewModel.currentURL {
            Menu {
                ShareLink(item: url) {
                    Label("Поделиться ссылкой", systemImage: "square.and.arrow.up")
                }
                Link(destination: url) {
                    Label("Открыть в браузере", systemImage: "safari")
                }
            } label: {
                GlassCircleIcon(
                    systemName: "square.and.arrow.up",
                    opticalOffset: CGSize(width: 0.5, height: -0.5)
                )
            }
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .accessibilityLabel("Поделиться ссылкой на изображение")
        }
    }
}

/// Paging `TabView` paints an opaque page background; walk a few ancestors and clear it.
private struct GalleryPageBackgroundClearer: UIViewRepresentable {
    func makeUIView(context: Context) -> GalleryPageBackgroundView {
        GalleryPageBackgroundView()
    }

    func updateUIView(_ uiView: GalleryPageBackgroundView, context: Context) {}
}

private final class GalleryPageBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        clearOpaqueAncestors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clearOpaqueAncestors()
    }

    private func clearOpaqueAncestors() {
        var ancestor = superview
        var hops = 0
        while let view = ancestor, hops < 6 {
            view.backgroundColor = .clear
            ancestor = view.superview
            hops += 1
        }
    }
}

private enum WindowSafeArea {
    static var insets: UIEdgeInsets {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        let window = windows.first(where: \.isKeyWindow) ?? windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    }
}
