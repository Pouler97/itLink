import SwiftUI

struct ThumbnailCellView: View {
    @State private var viewModel: ThumbnailCellViewModel
    @State private var cellFrame: CGRect = .zero
    let isHiddenForHero: Bool
    let onOpen: (UIImage?, CGRect) -> Void

    init(
        item: ImageGridItem,
        isHiddenForHero: Bool = false,
        onOpen: @escaping (UIImage?, CGRect) -> Void
    ) {
        _viewModel = State(initialValue: ThumbnailCellViewModel(item: item))
        self.isHiddenForHero = isHiddenForHero
        self.onOpen = onOpen
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                cellContent
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .background(cellFrameReporter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits((viewModel.state == .loaded || viewModel.state == .failed) ? .isButton : [])
    }

    private var cellFrameReporter: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: GalleryCellFrameKey.self,
                    value: [viewModel.item.id: geometry.frame(in: .global)]
                )
                .onAppear {
                    cellFrame = geometry.frame(in: .global)
                }
                .onChange(of: geometry.frame(in: .global)) { _, frame in
                    cellFrame = frame
                }
        }
    }

    @ViewBuilder
    private var cellContent: some View {
        switch viewModel.state {
        case .placeholder:
            PlaceholderView(style: .nonLink)

        case .idle, .loading, .failed:
            PlaceholderView(
                style: viewModel.state == .failed ? .failed : .loading,
                onRetry: { viewModel.retry() }
            )
            .task { viewModel.loadIfNeeded() }
            .onDisappear { viewModel.cancelLoading() }

        case .loaded:
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .opacity(isHiddenForHero ? 0 : 1)
                    .onTapGesture { onOpen(image, cellFrame) }
            } else {
                PlaceholderView(style: .nonImage)
            }
        }
    }

    private var accessibilityLabel: String {
        switch viewModel.state {
        case .loaded:
            return "Превью изображения"
        case .failed:
            return "Не удалось загрузить изображение, доступна повторная попытка"
        case .placeholder:
            return "Не ссылка"
        case .loading, .idle:
            return "Загрузка изображения"
        }
    }
}
