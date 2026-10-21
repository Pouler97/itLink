import ImageIO
import UIKit

nonisolated enum ImageIODecoder: Sendable {
    /// 120 pt cells at @3x.
    static let thumbnailMaxPixelSize = 360
    /// Caps decoded originals so a 20 MP file does not sit fully in RAM.
    static let displayMaxPixelSize = 4096

    static func thumbnail(from data: Data, maxPixelSize: Int = thumbnailMaxPixelSize) -> UIImage? {
        downsample(from: data, maxPixelSize: maxPixelSize)
    }

    static func displayImage(from data: Data, maxPixelSize: Int = displayMaxPixelSize) -> UIImage? {
        downsample(from: data, maxPixelSize: maxPixelSize)
    }

    static func isDecodableImage(_ data: Data) -> Bool {
        downsample(from: data, maxPixelSize: 32) != nil
    }

    private static func downsample(from data: Data, maxPixelSize: Int) -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        guard CGImageSourceGetCount(source) > 0 else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
