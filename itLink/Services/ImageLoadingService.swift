import UIKit

enum ImageLoadingError: Error {
    case invalidImageData
}

actor ImageLoadingService {
    static let shared = ImageLoadingService()

    private let httpClient: HTTPClient
    private let cacheStore: ImageCacheStore
    private let maxConcurrentDownloads: Int

    private var inFlightData: [String: Task<Data, Error>] = [:]
    private var inFlightOriginals: [String: Task<UIImage, Error>] = [:]
    private var inFlightThumbnails: [String: Task<UIImage, Error>] = [:]
    private let permitLock = NSLock()
    private var activeDownloads = 0
    private var downloadWaiters: [CheckedContinuation<Void, Never>] = []

    init(
        httpClient: HTTPClient = .shared,
        cacheStore: ImageCacheStore = .shared,
        maxConcurrentDownloads: Int = 4
    ) {
        self.httpClient = httpClient
        self.cacheStore = cacheStore
        self.maxConcurrentDownloads = max(1, maxConcurrentDownloads)
    }

    func cachedThumbnail(for url: URL) async -> UIImage? {
        if let cached = await cacheStore.thumbnailImage(for: url) {
            return cached
        }

        guard let data = await cacheStore.originalData(for: url),
              let thumbnail = ImageIODecoder.thumbnail(from: data) else {
            return nil
        }

        try? await cacheStore.storeThumbnail(thumbnail, for: url)
        return thumbnail
    }

    func thumbnail(for url: URL) async throws -> UIImage {
        if let cached = await cachedThumbnail(for: url) {
            return cached
        }

        let key = await cacheStore.cacheKey(for: url)
        if let existing = inFlightThumbnails[key] {
            return try await existing.value
        }

        let task = Task<UIImage, Error> {
            let data = try await self.originalData(for: url)
            guard let thumbnail = ImageIODecoder.thumbnail(from: data) else {
                throw ImageLoadingError.invalidImageData
            }
            try? await self.cacheStore.storeThumbnail(thumbnail, for: url)
            return thumbnail
        }

        inFlightThumbnails[key] = task
        defer { inFlightThumbnails.removeValue(forKey: key) }
        return try await task.value
    }

    func originalImage(for url: URL) async throws -> UIImage {
        if let cached = await cacheStore.originalImage(for: url) {
            return cached
        }

        let key = await cacheStore.cacheKey(for: url)
        if let existing = inFlightOriginals[key] {
            return try await existing.value
        }

        let task = Task<UIImage, Error> {
            let data = try await self.originalData(for: url)
            guard let image = ImageIODecoder.displayImage(from: data) else {
                throw ImageLoadingError.invalidImageData
            }
            await self.cacheStore.storeOriginalImage(image, for: url)
            return image
        }

        inFlightOriginals[key] = task
        defer { inFlightOriginals.removeValue(forKey: key) }
        return try await task.value
    }

    private func originalData(for url: URL) async throws -> Data {
        if let cached = await cacheStore.originalData(for: url) {
            return cached
        }

        let key = await cacheStore.cacheKey(for: url)
        if let existing = inFlightData[key] {
            return try await existing.value
        }

        let task = Task<Data, Error> {
            let data = try await self.withDownloadPermit {
                try await self.httpClient.data(from: url)
            }
            guard ImageIODecoder.isDecodableImage(data) else {
                throw ImageLoadingError.invalidImageData
            }
            try? await self.cacheStore.storeOriginalData(data, for: url)
            return data
        }

        inFlightData[key] = task
        defer { inFlightData.removeValue(forKey: key) }
        return try await task.value
    }

    private func withDownloadPermit<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        await acquireDownloadPermit()
        defer { releaseDownloadPermit() }
        return try await operation()
    }

    private func acquireDownloadPermit() async {
        await withCheckedContinuation { continuation in
            permitLock.lock()
            if activeDownloads < maxConcurrentDownloads {
                activeDownloads += 1
                permitLock.unlock()
                continuation.resume()
            } else {
                downloadWaiters.append(continuation)
                permitLock.unlock()
            }
        }
    }

    private func releaseDownloadPermit() {
        permitLock.lock()
        if downloadWaiters.isEmpty {
            activeDownloads = max(0, activeDownloads - 1)
            permitLock.unlock()
            return
        }
        let waiter = downloadWaiters.removeFirst()
        permitLock.unlock()
        waiter.resume()
    }
}
