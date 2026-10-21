import Foundation
import Observation
import UIKit

enum GalleryImageState: Equatable {
    case loading
    case loaded
    case failed
}

@MainActor
@Observable
final class ImageGalleryViewModel {
    let items: [ImageGridItem]
    private(set) var currentIndex: Int
    private(set) var states: [String: GalleryImageState] = [:]
    private(set) var images: [String: UIImage] = [:]

    var isChromeVisible = true

    private let imageLoader: any ImageLoadingProviding
    private var loadTasks: [String: Task<Void, Never>] = [:]
    private var pagingLoadTask: Task<Void, Never>?

    init(items: [ImageGridItem], startIndex: Int, imageLoader: any ImageLoadingProviding = ImageLoadingService.shared) {
        self.items = items
        self.currentIndex = min(max(startIndex, 0), max(items.count - 1, 0))
        self.imageLoader = imageLoader
    }

    func cancelAllLoading() {
        pagingLoadTask?.cancel()
        pagingLoadTask = nil
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
        clearLoadingStatesWithoutImages()
    }

    var currentItem: ImageGridItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var currentURL: URL? {
        guard case let .imageURL(url) = currentItem?.kind else { return nil }
        return url
    }

    func state(for item: ImageGridItem) -> GalleryImageState {
        states[item.id] ?? .loading
    }

    func image(for item: ImageGridItem) -> UIImage? {
        images[item.id]
    }

    func selectIndex(_ index: Int) {
        let previousIndex = currentIndex
        let clampedIndex = min(max(index, 0), max(items.count - 1, 0))
        currentIndex = clampedIndex
        guard clampedIndex != previousIndex else { return }

        pagingLoadTask?.cancel()
        pagingLoadTask = Task {
            defer {
                if !Task.isCancelled {
                    pagingLoadTask = nil
                }
            }
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            loadImage(at: currentIndex)
            preloadNeighbors(around: currentIndex)
        }
    }

    func onAppear() {
        loadImage(at: currentIndex)
        preloadNeighbors(around: currentIndex)
    }

    func retry(item: ImageGridItem) {
        loadImage(for: item, force: true)
    }

    func toggleChrome() {
        isChromeVisible.toggle()
    }

    private func preloadNeighbors(around index: Int) {
        for offset in [-1, 1] {
            loadImage(at: index + offset)
        }
    }

    private func loadImage(at index: Int) {
        guard items.indices.contains(index) else { return }
        loadImage(for: items[index], force: false)
    }

    private func loadImage(for item: ImageGridItem, force: Bool) {
        guard case let .imageURL(url) = item.kind else { return }

        if !force, images[item.id] != nil {
            states[item.id] = .loaded
            return
        }

        if !force, loadTasks[item.id] != nil { return }

        loadTasks[item.id]?.cancel()
        states[item.id] = .loading

        loadTasks[item.id] = Task {
            defer { loadTasks.removeValue(forKey: item.id) }

            do {
                let image = try await imageLoader.originalImage(for: url)
                guard !Task.isCancelled else {
                    clearLoadingState(for: item.id)
                    return
                }
                images[item.id] = image
                states[item.id] = .loaded
            } catch {
                guard !Task.isCancelled else {
                    clearLoadingState(for: item.id)
                    return
                }
                states[item.id] = .failed
            }
        }
    }

    private func clearLoadingStatesWithoutImages() {
        for (id, state) in states where state == .loading && images[id] == nil {
            states.removeValue(forKey: id)
        }
    }

    private func clearLoadingState(for id: String) {
        guard images[id] == nil else { return }
        states.removeValue(forKey: id)
    }
}
