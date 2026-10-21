import SwiftUI
import UIKit

private final class BoundsAwareScrollView: UIScrollView {
    var onBoundsReady: (() -> Void)?
    private var lastReportedBounds: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard bounds.size != lastReportedBounds else { return }
        lastReportedBounds = bounds.size
        onBoundsReady?()
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = BoundsAwareScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.isScrollEnabled = false

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.tag = Coordinator.imageViewTag
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap)
        )
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        let coordinator = context.coordinator
        coordinator.scrollView = scrollView
        scrollView.onBoundsReady = { [weak coordinator] in
            guard let coordinator,
                  let scrollView = coordinator.scrollView,
                  let imageView = scrollView.viewWithTag(Coordinator.imageViewTag) as? UIImageView else { return }
            coordinator.layoutImage(in: scrollView, imageView: imageView)
        }
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(Coordinator.imageViewTag) as? UIImageView else {
            return
        }

        context.coordinator.onTap = onTap

        guard imageView.image !== image else { return }

        imageView.image = image
        context.coordinator.layoutImage(in: scrollView, imageView: imageView)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        static let imageViewTag = 1001

        var onTap: () -> Void
        weak var scrollView: UIScrollView?
        private var isLayouting = false
        private var lastLayoutSignature: String?

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(Self.imageViewTag)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            scrollView.isScrollEnabled = scrollView.zoomScale > scrollView.minimumZoomScale + 0.001
            guard let imageView = scrollView.viewWithTag(Self.imageViewTag) as? UIImageView else { return }
            centerImage(in: scrollView, imageView: imageView)
        }

        @objc func handleSingleTap() {
            onTap()
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            let point = recognizer.location(in: scrollView)
            let zoomRect = zoomRect(for: scrollView, scale: 2.5, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }

        func layoutImage(in scrollView: UIScrollView, imageView: UIImageView) {
            guard !isLayouting else { return }
            guard scrollView.bounds.width > 0, scrollView.bounds.height > 0 else { return }

            let imageSize = imageView.image?.size ?? .zero
            let signature = "\(Int(scrollView.bounds.width))x\(Int(scrollView.bounds.height))|\(Int(imageSize.width))x\(Int(imageSize.height))"
            let shouldResetZoom = lastLayoutSignature != signature
            lastLayoutSignature = signature

            isLayouting = true
            defer { isLayouting = false }

            if shouldResetZoom {
                scrollView.zoomScale = scrollView.minimumZoomScale
            }

            guard let image = imageView.image, image.size.width > 0, image.size.height > 0 else {
                imageView.frame = CGRect(origin: .zero, size: scrollView.bounds.size)
                scrollView.contentSize = scrollView.bounds.size
                return
            }

            let bounds = scrollView.bounds.size
            let widthRatio = bounds.width / image.size.width
            let heightRatio = bounds.height / image.size.height
            let ratio = min(widthRatio, heightRatio)
            let fittedSize = CGSize(
                width: image.size.width * ratio,
                height: image.size.height * ratio
            )

            imageView.frame = CGRect(origin: .zero, size: fittedSize)
            scrollView.contentSize = fittedSize
            centerImage(in: scrollView, imageView: imageView)
        }

        private func centerImage(in scrollView: UIScrollView, imageView: UIImageView) {
            let boundsSize = scrollView.bounds.size
            var frame = imageView.frame

            frame.origin.x = frame.width < boundsSize.width
                ? (boundsSize.width - frame.width) / 2
                : 0
            frame.origin.y = frame.height < boundsSize.height
                ? (boundsSize.height - frame.height) / 2
                : 0

            imageView.frame = frame
        }

        private func zoomRect(for scrollView: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
            let zoomScale = min(max(scrollView.minimumZoomScale * scale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            let size = CGSize(
                width: scrollView.bounds.width / zoomScale,
                height: scrollView.bounds.height / zoomScale
            )
            let origin = CGPoint(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2
            )
            return CGRect(origin: origin, size: size)
        }
    }
}
