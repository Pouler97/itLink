import Foundation
import Observation

enum GridLoadingState: Equatable {
    case loading
    case loaded
    case failed
}

@MainActor
@Observable
final class GridViewModel {
    static let pageSize = 12

    private(set) var items: [ImageGridItem] = []
    private(set) var visibleCount = 0
    private(set) var loadingState: GridLoadingState = .loading

    private let listService: ImageListService
    private var needsRemoteRefresh = false
    private var hasStarted = false

    init(listService: ImageListService = .shared) {
        self.listService = listService
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        NetworkMonitor.shared.onConnectivityRestored = { [weak self] in
            Task { @MainActor in
                await self?.refreshIfNeeded()
            }
        }

        Task {
            await loadInitial()
        }
    }

    func refreshIfNeeded() async {
        guard needsRemoteRefresh || items.isEmpty else { return }
        await loadFromNetwork()
    }

    func retryListLoad() {
        Task {
            await loadFromNetwork()
        }
    }

    var displayedItems: [ImageGridItem] {
        Array(items.prefix(visibleCount))
    }

    var imageItems: [ImageGridItem] {
        items.filter {
            if case .imageURL = $0.kind { return true }
            return false
        }
    }

    func revealMoreIfNeeded(for item: ImageGridItem) {
        guard let lastVisible = displayedItems.last, lastVisible.id == item.id else { return }
        guard visibleCount < items.count else { return }
        visibleCount = min(items.count, visibleCount + Self.pageSize)
    }

    func galleryStartIndex(for item: ImageGridItem) -> Int? {
        imageItems.firstIndex(of: item)
    }

    private func loadInitial() async {
        if let cached = await listService.cachedItemsIfAvailable(), !cached.isEmpty {
            replaceItems(cached)
            loadingState = .loaded
        }

        await loadFromNetwork()
    }

    private func loadFromNetwork() async {
        if items.isEmpty {
            loadingState = .loading
        }

        do {
            let fetched = try await listService.fetchRemoteItems()
            replaceItems(fetched)
            loadingState = .loaded
            needsRemoteRefresh = false
        } catch {
            if items.isEmpty {
                loadingState = .failed
            }
            needsRemoteRefresh = true
        }
    }

    func applyItemsForTesting(_ newItems: [ImageGridItem]) {
        replaceItems(newItems)
    }

    private func replaceItems(_ newItems: [ImageGridItem]) {
        items = newItems
        if visibleCount == 0 {
            visibleCount = min(Self.pageSize, newItems.count)
        } else {
            visibleCount = min(max(visibleCount, Self.pageSize), newItems.count)
        }
    }
}
