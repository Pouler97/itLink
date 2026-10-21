import SwiftUI

struct ImageGalleryView: View {
    @State private var viewModel: ImageGalleryViewModel
    @State private var pageIndex: Int

    init(items: [ImageGridItem], startIndex: Int) {
        let clampedStart = min(max(startIndex, 0), max(items.count - 1, 0))
        _viewModel = State(initialValue: ImageGalleryViewModel(items: items, startIndex: clampedStart))
        _pageIndex = State(initialValue: clampedStart)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $pageIndex) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    GalleryPageContent(
                        item: item,
                        state: viewModel.state(for: item),
                        image: viewModel.image(for: item),
                        onToggleChrome: { viewModel.toggleChrome() },
                        onRetry: { viewModel.retry(item: item) }
                    )
                    .equatable()
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: viewModel.isChromeVisible ? .automatic : .never))
            .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(viewModel.isChromeVisible ? .visible : .hidden, for: .navigationBar)
        .toolbarBackground(viewModel.isChromeVisible ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if viewModel.isChromeVisible {
                ToolbarItem(placement: .topBarTrailing) {
                    shareMenu
                }
            }
        }
        .statusBarHidden(!viewModel.isChromeVisible)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.cancelAllLoading()
        }
        .onChange(of: pageIndex) { _, newIndex in
            viewModel.selectIndex(newIndex)
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
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Поделиться ссылкой на изображение")
        }
    }
}
