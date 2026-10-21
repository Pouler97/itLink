import SwiftUI
import UIKit

struct GalleryPageContent: View, Equatable {
    let item: ImageGridItem
    let state: GalleryImageState
    let image: UIImage?
    var isActive: Bool = true
    let onToggleChrome: () -> Void
    let onRetry: () -> Void
    var onDismissChanged: (CGSize) -> Void = { _ in }
    var onDismissEnded: (Bool) -> Void = { _ in }
    var onZoomChanged: (Bool) -> Void = { _ in }

    static func == (lhs: GalleryPageContent, rhs: GalleryPageContent) -> Bool {
        lhs.item.id == rhs.item.id
            && lhs.state == rhs.state
            && lhs.image === rhs.image
            && lhs.isActive == rhs.isActive
    }

    var body: some View {
        switch state {
        case .loading:
            ArcSpinnerView(size: 32, lineWidth: 2.5, color: .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleChrome)
                .simultaneousGesture(dismissDrag)

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
            .simultaneousGesture(dismissDrag)

        case .loaded:
            if let image {
                ZoomableImageView(
                    image: image,
                    isActive: isActive,
                    onTap: onToggleChrome,
                    onDismissChanged: onDismissChanged,
                    onDismissEnded: onDismissEnded,
                    onZoomChanged: onZoomChanged
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ArcSpinnerView(size: 32, lineWidth: 2.5, color: .white)
            }
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let translation = value.translation
                guard translation.height > 0, translation.height >= abs(translation.width) else { return }
                onDismissChanged(translation)
            }
            .onEnded { value in
                let translation = value.translation.height
                let predicted = value.predictedEndTranslation.height
                onDismissEnded(translation > 120 || predicted > 240)
            }
    }
}
