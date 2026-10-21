import SwiftUI

struct ThumbnailCellView: View {
    @State private var viewModel: ThumbnailCellViewModel
    let onOpen: () -> Void

    init(item: ImageGridItem, onOpen: @escaping () -> Void) {
        _viewModel = State(initialValue: ThumbnailCellViewModel(item: item))
        self.onOpen = onOpen
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .placeholder:
                PlaceholderView(style: .nonLink)

            case .idle, .loading:
                PlaceholderView(style: .loading)
                    .task { viewModel.loadIfNeeded() }
                    .onDisappear { viewModel.cancelLoading() }

            case .loaded:
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onOpen)
                } else {
                    PlaceholderView(style: .nonImage)
                }

            case .failed:
                PlaceholderView(style: .failed) {
                    viewModel.retry()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(viewModel.state == .loaded ? .isButton : [])
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
