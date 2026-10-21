import CryptoKit
import Foundation
import UIKit

enum ImageCacheKind: String, Sendable {
    case original
    case thumbnail
}

enum ImageCacheStoreError: Error {
    case encodingFailed
}

actor ImageCacheStore {
    static let shared = ImageCacheStore()

    private let diskCache: DiskCache
    private let thumbnailMemoryCache = NSCache<NSString, UIImage>()
    private let originalMemoryCache = NSCache<NSString, UIImage>()

    init(diskCache: DiskCache = .shared) {
        self.diskCache = diskCache
        thumbnailMemoryCache.countLimit = 200
        thumbnailMemoryCache.totalCostLimit = 32 * 1024 * 1024
        originalMemoryCache.countLimit = 12
        originalMemoryCache.totalCostLimit = 64 * 1024 * 1024
    }

    nonisolated static func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func cacheKey(for url: URL) -> String {
        Self.cacheKey(for: url)
    }

    func originalData(for url: URL) -> Data? {
        diskCache.read(fileName: cacheKey(for: url), subdirectory: ImageCacheKind.original.rawValue)
    }

    func thumbnailImage(for url: URL) -> UIImage? {
        cachedImage(for: url, kind: .thumbnail)
    }

    func originalImage(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        let memoryKey = memoryKey(kind: .original, key: key)
        return originalMemoryCache.object(forKey: memoryKey)
    }

    func storeOriginalData(_ data: Data, for url: URL) throws {
        try diskCache.write(
            data,
            fileName: cacheKey(for: url),
            subdirectory: ImageCacheKind.original.rawValue
        )
    }

    func storeOriginalImage(_ image: UIImage, for url: URL) {
        remember(image, for: url, kind: .original)
    }

    func storeThumbnail(_ image: UIImage, for url: URL) throws {
        remember(image, for: url, kind: .thumbnail)

        guard let data = image.jpegData(compressionQuality: 0.82) ?? image.pngData() else {
            throw ImageCacheStoreError.encodingFailed
        }
        try diskCache.write(
            data,
            fileName: cacheKey(for: url),
            subdirectory: ImageCacheKind.thumbnail.rawValue
        )
    }

    private func cachedImage(for url: URL, kind: ImageCacheKind) -> UIImage? {
        let key = cacheKey(for: url)
        let memoryKey = memoryKey(kind: kind, key: key)

        if let cached = cache(for: kind).object(forKey: memoryKey) {
            return cached
        }

        guard let data = diskCache.read(fileName: key, subdirectory: kind.rawValue),
              let image = decodedImage(from: data, kind: kind) else {
            return nil
        }

        remember(image, memoryKey: memoryKey, kind: kind)
        return image
    }

    private func decodedImage(from data: Data, kind: ImageCacheKind) -> UIImage? {
        switch kind {
        case .thumbnail:
            return ImageIODecoder.thumbnail(from: data)
        case .original:
            return ImageIODecoder.displayImage(from: data)
        }
    }

    private func remember(_ image: UIImage, for url: URL, kind: ImageCacheKind) {
        remember(image, memoryKey: memoryKey(kind: kind, key: cacheKey(for: url)), kind: kind)
    }

    private func remember(_ image: UIImage, memoryKey: NSString, kind: ImageCacheKind) {
        cache(for: kind).setObject(image, forKey: memoryKey, cost: pixelCost(of: image))
    }

    private func cache(for kind: ImageCacheKind) -> NSCache<NSString, UIImage> {
        switch kind {
        case .thumbnail:
            return thumbnailMemoryCache
        case .original:
            return originalMemoryCache
        }
    }

    private func memoryKey(kind: ImageCacheKind, key: String) -> NSString {
        "\(kind.rawValue)-\(key)" as NSString
    }

    private func pixelCost(of image: UIImage) -> Int {
        let width = image.size.width * image.scale
        let height = image.size.height * image.scale
        return Int(width * height * 4)
    }
}
