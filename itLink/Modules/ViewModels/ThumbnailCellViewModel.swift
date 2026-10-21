import Foundation
import Observation
import UIKit

enum ThumbnailLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
    case placeholder
}

@MainActor
@Observable
final class ThumbnailCellViewModel {
    let item: ImageGridItem

    private(set) var state: ThumbnailLoadState = .idle
    private(set) var image: UIImage?

    private let imageLoader: any ImageLoadingProviding
    private let loadTimeoutNanoseconds: UInt64?
    private var loadTask: Task<Void, Never>?

    init(
        item: ImageGridItem,
        imageLoader: any ImageLoadingProviding = ImageLoadingService.shared,
        loadTimeoutNanoseconds: UInt64? = nil
    ) {
        self.item = item
        self.imageLoader = imageLoader
        self.loadTimeoutNanoseconds = loadTimeoutNanoseconds

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
        guard state == .idle else { return }
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
                let thumbnail = try await thumbnailWithTimeout(from: url)
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

    private func thumbnailWithTimeout(from url: URL) async throws -> UIImage {
        guard let loadTimeoutNanoseconds else {
            return try await imageLoader.thumbnail(for: url)
        }

        return try await withThrowingTaskGroup(of: UIImage.self) { group in
            group.addTask {
                try await self.imageLoader.thumbnail(for: url)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: loadTimeoutNanoseconds)
                throw URLError(.timedOut)
            }

            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            group.cancelAll()
            return result
        }
    }
}
