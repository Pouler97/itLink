import SwiftUI

struct GalleryPager: View {
    let items: [ImageGridItem]
    @Binding var selectedItemID: String
    let stateForItem: (ImageGridItem) -> GalleryImageState
    let imageForItem: (ImageGridItem) -> UIImage?
    let isInteractive: Bool
    let onToggleChrome: () -> Void
    let onRetry: (ImageGridItem) -> Void
    let onDismissChanged: (CGSize) -> Void
    let onDismissEnded: (Bool) -> Void

    @State private var isImageZoomed = false

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(items) { item in
                            GalleryPageContent(
                                item: item,
                                state: stateForItem(item),
                                image: imageForItem(item),
                                isActive: item.id == selectedItemID,
                                onToggleChrome: onToggleChrome,
                                onRetry: { onRetry(item) },
                                onDismissChanged: onDismissChanged,
                                onDismissEnded: onDismissEnded,
                                onZoomChanged: { zoomed in
                                    if item.id == selectedItemID {
                                        isImageZoomed = zoomed
                                    }
                                }
                            )
                            .equatable()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(item.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: scrollPosition)
                .scrollIndicators(.hidden)
                .scrollDisabled(isImageZoomed || !isInteractive)
                .contentMargins(.all, 0, for: .scrollContent)
                .onChange(of: selectedItemID) { _, _ in
                    isImageZoomed = false
                }
                .onChange(of: items.count) { _, _ in
                    guard items.contains(where: { $0.id == selectedItemID }) else { return }
                    let currentID = selectedItemID
                    DispatchQueue.main.async {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            scrollProxy.scrollTo(currentID, anchor: .leading)
                        }
                    }
                }
            }
        }
        .opacity(isInteractive ? 1 : 0)
        .allowsHitTesting(isInteractive)
        .ignoresSafeArea()
    }

    private var scrollPosition: Binding<String?> {
        Binding(
            get: { selectedItemID.isEmpty ? nil : selectedItemID },
            set: { newValue in
                if let newValue, newValue != selectedItemID {
                    selectedItemID = newValue
                }
            }
        )
    }
}
