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
    private let sourceItems: [ImageGridItem]
    private(set) var pageItems: [ImageGridItem]
    private(set) var thumbnails: [String: UIImage] = [:]
    private(set) var currentIndex: Int
    private(set) var states: [String: GalleryImageState] = [:]
    private(set) var images: [String: UIImage] = [:]

    var isChromeVisible = true

    private let imageLoader: any ImageLoadingProviding
    private var loadTasks: [String: Task<Void, Never>] = [:]
    private var pagingLoadTask: Task<Void, Never>?
    private var pageResolveTask: Task<Void, Never>?

    init(items: [ImageGridItem], startIndex: Int, imageLoader: any ImageLoadingProviding = ImageLoadingService.shared) {
        self.sourceItems = items
        self.imageLoader = imageLoader
        let clampedStart = min(max(startIndex, 0), max(items.count - 1, 0))
        if items.indices.contains(clampedStart) {
            self.pageItems = [items[clampedStart]]
            self.currentIndex = 0
        } else {
            self.pageItems = []
            self.currentIndex = 0
        }
    }

    func cancelAllLoading() {
        pageResolveTask?.cancel()
        pageResolveTask = nil
        pagingLoadTask?.cancel()
        pagingLoadTask = nil
        loadTasks.values.forEach { $0.cancel() }
        loadTasks.removeAll()
        clearLoadingStatesWithoutImages()
    }

    var currentItem: ImageGridItem? {
        guard pageItems.indices.contains(currentIndex) else { return nil }
        return pageItems[currentIndex]
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
        let clampedIndex = min(max(index, 0), max(pageItems.count - 1, 0))
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
        resolveValidPages()
        loadImage(at: currentIndex)
        preloadNeighbors(around: currentIndex)
    }

    func index(of itemID: String) -> Int? {
        pageItems.firstIndex(where: { $0.id == itemID })
    }

    private func resolveValidPages() {
        pageResolveTask?.cancel()
        pageResolveTask = Task {
            defer {
                if !Task.isCancelled {
                    pageResolveTask = nil
                }
            }

            var validItems: [ImageGridItem] = []
            var loadedThumbnails: [String: UIImage] = [:]
            let currentID = currentItem?.id

            for item in sourceItems {
                if Task.isCancelled { return }
                guard case let .imageURL(url) = item.kind else { continue }
                if let thumbnail = await imageLoader.cachedThumbnail(for: url) {
                    loadedThumbnails[item.id] = thumbnail
                    validItems.append(item)
                    continue
                }
                if item.id == currentID {
                    validItems.append(item)
                }
            }

            if Task.isCancelled { return }

            thumbnails = loadedThumbnails
            pageItems = validItems
            if let currentID, let index = validItems.firstIndex(where: { $0.id == currentID }) {
                currentIndex = index
            } else {
                currentIndex = min(currentIndex, max(validItems.count - 1, 0))
            }

            loadImage(at: currentIndex)
            preloadNeighbors(around: currentIndex)
        }
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
        guard pageItems.indices.contains(index) else { return }
        loadImage(for: pageItems[index], force: false)
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
