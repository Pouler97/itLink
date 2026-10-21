import SwiftUI

struct GridView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel = GridViewModel()
    @State private var galleryStartIndex: Int?
    @State private var cellFrames: [String: CGRect] = [:]
    @State private var sourceFrame: CGRect = .zero
    @State private var heroPreview: UIImage?
    @State private var heroHiddenID: String?

    private var sizeProfile: GridSizeProfile {
        horizontalSizeClass == .regular ? .regular : .compact
    }

    private var layoutMetrics: GridLayoutCalculator.Metrics {
        GridLayoutCalculator.metrics(for: sizeProfile)
    }

    private var gridColumns: [GridItem] {
        let metrics = layoutMetrics
        return [
            GridItem(
                .adaptive(
                    minimum: metrics.minCellWidth,
                    maximum: metrics.maxCellWidth
                ),
                spacing: metrics.spacing
            )
        ]
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Изображения")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .onPreferenceChange(GalleryCellFrameKey.self) { cellFrames = $0 }
        }
        .overlay {
            if let startIndex = galleryStartIndex {
                ImageGalleryView(
                    items: viewModel.imageItems,
                    startIndex: startIndex,
                    cellFrames: cellFrames,
                    sourceFrame: sourceFrame,
                    previewImage: heroPreview,
                    onHeroItemChange: { heroHiddenID = $0 },
                    onClose: closeGallery
                )
            }
        }
        .onAppear {
            viewModel.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadingState {
        case .loading where viewModel.items.isEmpty:
            VStack(spacing: 12) {
                ArcSpinnerView(size: 32, lineWidth: 2.5)
                Text("Загрузка списка…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed where viewModel.items.isEmpty:
            VStack(spacing: 16) {
                Image(systemName: "wifi.slash")
                    .font(.largeTitle)
                Text("Не удалось загрузить список изображений")
                    .font(.headline)
                Button("Повторить", action: viewModel.retryListLoad)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        default:
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: layoutMetrics.spacing) {
                    ForEach(viewModel.displayedItems) { item in
                        ThumbnailCellView(
                            item: item,
                            isHiddenForHero: heroHiddenID == item.id
                        ) { preview, frame in
                            openGallery(for: item, preview: preview, frame: frame)
                        }
                        .onAppear {
                            viewModel.revealMoreIfNeeded(for: item)
                        }
                    }
                }
                .padding(layoutMetrics.padding)
            }
        }
    }

    private func openGallery(for item: ImageGridItem, preview: UIImage?, frame: CGRect) {
        guard let index = viewModel.galleryStartIndex(for: item) else { return }
        heroPreview = preview
        sourceFrame = frame.width > 1 ? frame : (cellFrames[item.id] ?? .zero)
        heroHiddenID = item.id
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            galleryStartIndex = index
        }
    }

    private func closeGallery() {
        heroHiddenID = nil
        heroPreview = nil
        sourceFrame = .zero
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            galleryStartIndex = nil
        }
    }
}

#Preview {
    GridView()
        .preferredColorScheme(.dark)
}
