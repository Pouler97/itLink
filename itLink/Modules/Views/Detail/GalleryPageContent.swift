import SwiftUI
import UIKit

struct GalleryPageContent: View, Equatable {
    let item: ImageGridItem
    let state: GalleryImageState
    let image: UIImage?
    let onToggleChrome: () -> Void
    let onRetry: () -> Void

    static func == (lhs: GalleryPageContent, rhs: GalleryPageContent) -> Bool {
        lhs.item.id == rhs.item.id
            && lhs.state == rhs.state
            && lhs.image === rhs.image
    }

    var body: some View {
        switch state {
        case .loading:
            ArcSpinnerView(size: 32, lineWidth: 2.5, color: .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleChrome)

        case .failed:
            VStack(spacing: 16) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.8))
                Button("Повторить", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleChrome)

        case .loaded:
            if let image {
                ZoomableImageView(image: image, onTap: onToggleChrome)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ArcSpinnerView(size: 32, lineWidth: 2.5, color: .white)
            }
        }
    }
}
