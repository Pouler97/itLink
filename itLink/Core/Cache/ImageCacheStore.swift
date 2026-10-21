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
    private let memoryCache = NSCache<NSString, UIImage>()

    init(diskCache: DiskCache = .shared) {
        self.diskCache = diskCache
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 64 * 1024 * 1024
    }

    func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
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
        return memoryCache.object(forKey: memoryKey)
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

        if let cached = memoryCache.object(forKey: memoryKey) {
            return cached
        }

        guard let data = diskCache.read(fileName: key, subdirectory: kind.rawValue),
              let image = UIImage(data: data) else {
            return nil
        }

        remember(image, memoryKey: memoryKey)
        return image
    }

    private func remember(_ image: UIImage, for url: URL, kind: ImageCacheKind) {
        remember(image, memoryKey: memoryKey(kind: kind, key: cacheKey(for: url)))
    }

    private func remember(_ image: UIImage, memoryKey: NSString) {
        memoryCache.setObject(image, forKey: memoryKey, cost: pixelCost(of: image))
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
