import Foundation
import Observation

enum GridLoadingState: Equatable {
    case loading
    case loaded
    case failed(message: String)
}

@MainActor
@Observable
final class GridViewModel {
    private(set) var items: [ImageGridItem] = []
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

    var imageItems: [ImageGridItem] {
        items.filter {
            if case .imageURL = $0.kind { return true }
            return false
        }
    }

    func galleryStartIndex(for item: ImageGridItem) -> Int? {
        imageItems.firstIndex(of: item)
    }

    private func loadInitial() async {
        if let cached = await listService.cachedItemsIfAvailable(), !cached.isEmpty {
            items = cached
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
            items = fetched
            loadingState = .loaded
            needsRemoteRefresh = false
        } catch {
            if items.isEmpty {
                loadingState = .failed(message: error.localizedDescription)
            }
            needsRemoteRefresh = true
        }
    }
}
