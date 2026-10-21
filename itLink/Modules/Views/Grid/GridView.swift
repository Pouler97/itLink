import SwiftUI

private struct GalleryRoute: Hashable {
    let startIndex: Int
}

struct GridView: View {
    @State private var viewModel = GridViewModel()
    @State private var galleryRoute: GalleryRoute?

    private let gridColumns = [
        GridItem(
            .adaptive(
                minimum: GridLayoutCalculator.minCellWidth,
                maximum: GridLayoutCalculator.maxCellWidth
            ),
            spacing: GridLayoutCalculator.spacing
        )
    ]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Изображения")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationDestination(item: $galleryRoute) { route in
                    ImageGalleryView(
                        items: viewModel.imageItems,
                        startIndex: route.startIndex
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
                LazyVGrid(columns: gridColumns, spacing: GridLayoutCalculator.spacing) {
                    ForEach(viewModel.items) { item in
                        ThumbnailCellView(item: item) {
                            openGallery(for: item)
                        }
                    }
                }
                .padding(GridLayoutCalculator.padding)
            }
        }
    }

    private func openGallery(for item: ImageGridItem) {
        guard let index = viewModel.galleryStartIndex(for: item) else { return }
        galleryRoute = GalleryRoute(startIndex: index)
    }
}

#Preview {
    GridView()
        .preferredColorScheme(.dark)
}
