import SwiftUI
import UIKit

private enum GalleryChromeLayout {
    static let topOverlap: CGFloat = 52
    static let bottomOverlap: CGFloat = 22
    static let minimumPadding: CGFloat = 2
}

struct GalleryChrome: View {
    let items: [ImageGridItem]
    let thumbnails: [String: UIImage]
    let currentItemID: String?
    let shareURL: URL?
    let isShown: Bool
    let onBack: () -> Void
    let onSelect: (ImageGridItem) -> Void

    var body: some View {
        let insets = WindowSafeArea.insets
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            GalleryFilmstrip(
                items: items,
                thumbnails: thumbnails,
                currentItemID: currentItemID,
                onSelect: onSelect
            )
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 0)
        }
        .padding(.top, max(GalleryChromeLayout.minimumPadding, insets.top - GalleryChromeLayout.topOverlap))
        .padding(.bottom, max(GalleryChromeLayout.minimumPadding, insets.bottom - GalleryChromeLayout.bottomOverlap))
        .opacity(isShown ? 1 : 0)
        .allowsHitTesting(isShown)
    }

    private var topBar: some View {
        HStack {
            GlassIconButton(
                systemName: "chevron.left",
                accessibilityLabel: "Назад",
                action: onBack
            )

            Spacer()

            shareMenu
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var shareMenu: some View {
        if let shareURL {
            Menu {
                ShareLink(item: shareURL) {
                    Label("Поделиться ссылкой", systemImage: "square.and.arrow.up")
                }
                Link(destination: shareURL) {
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

private enum WindowSafeArea {
    static var insets: UIEdgeInsets {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        let window = windows.first(where: \.isKeyWindow) ?? windows.first
        return window?.safeAreaInsets ?? UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    }
}
