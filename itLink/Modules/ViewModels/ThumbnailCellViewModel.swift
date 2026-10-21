import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ThumbnailCellViewModel {
    let item: ImageGridItem

    private(set) var state: ThumbnailLoadState = .idle
    private(set) var image: UIImage?

    private let imageLoader: any ImageLoadingProviding
    private var loadTask: Task<Void, Never>?

    init(item: ImageGridItem, imageLoader: any ImageLoadingProviding = ImageLoadingService.shared) {
        self.item = item
        self.imageLoader = imageLoader

        switch item.kind {
        case .nonLink:
            state = .placeholder
        case .imageURL:
            state = .idle
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        if state == .loading {
            state = .idle
        }
    }

    func loadIfNeeded() {
        guard case .imageURL = item.kind else { return }
        guard state == .idle || state == .failed else { return }
        startLoading()
    }

    func retry() {
        guard case .imageURL = item.kind else { return }
        startLoading()
    }

    private func startLoading() {
        loadTask?.cancel()
        state = .loading
        image = nil

        guard case let .imageURL(url) = item.kind else { return }

        loadTask = Task {
            do {
                let thumbnail = try await imageLoader.thumbnail(for: url)
                guard !Task.isCancelled else {
                    state = .idle
                    return
                }
                image = thumbnail
                state = .loaded
            } catch {
                guard !Task.isCancelled else {
                    state = .idle
                    return
                }
                state = .failed
            }
        }
    }
}
