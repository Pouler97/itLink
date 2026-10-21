import SwiftUI

struct GalleryFilmstrip: View {
    let items: [ImageGridItem]
    let thumbnails: [String: UIImage]
    let currentItemID: String?
    let onSelect: (ImageGridItem) -> Void

    private let selectedSize: CGFloat = 52
    private let thumbSize: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let sideInset = max(0, (geometry.size.width - selectedSize) / 2)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(items) { item in
                            let isSelected = item.id == currentItemID
                            FilmstripThumbnail(
                                image: thumbnails[item.id],
                                isSelected: isSelected,
                                size: isSelected ? selectedSize : thumbSize
                            )
                            .id(item.id)
                            .onTapGesture { onSelect(item) }
                            .accessibilityLabel("Превью")
                            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.horizontal, sideInset)
                    .padding(.vertical, 6)
                }
                .onAppear {
                    scrollToCurrent(proxy: proxy, animated: false)
                }
                .onChange(of: currentItemID) { _, _ in
                    scrollToCurrent(proxy: proxy, animated: true)
                }
                .onChange(of: items.count) { _, _ in
                    scrollToCurrent(proxy: proxy, animated: false)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: items.isEmpty ? 0 : 68)
        .clipped()
    }

    private func scrollToCurrent(proxy: ScrollViewProxy, animated: Bool) {
        guard let currentItemID, items.contains(where: { $0.id == currentItemID }) else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(currentItemID, anchor: .center)
            }
        } else {
            proxy.scrollTo(currentItemID, anchor: .center)
        }
    }

}

private struct FilmstripThumbnail: View {
    let image: UIImage?
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
