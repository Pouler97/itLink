import UIKit
@testable import itLink

enum TestImageFactory {
    static func solidColor(
        size: CGSize = CGSize(width: 10, height: 10),
        color: UIColor = .red
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    static func jpegData(
        width: Int,
        height: Int,
        color: UIColor = .red
    ) -> Data {
        let image = solidColor(
            size: CGSize(width: width, height: height),
            color: color
        )
        return image.jpegData(compressionQuality: 0.95)!
    }
}

final class MockImageLoader: ImageLoadingProviding, @unchecked Sendable {
    var thumbnailDelayNanoseconds: UInt64 = 0
    var originalDelayNanoseconds: UInt64 = 0
    var thumbnailResult: Result<UIImage, Error> = .success(TestImageFactory.solidColor())
    var originalResult: Result<UIImage, Error> = .success(TestImageFactory.solidColor())

    func thumbnail(for url: URL) async throws -> UIImage {
        if thumbnailDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: thumbnailDelayNanoseconds)
        }
        return try thumbnailResult.get()
    }

    func originalImage(for url: URL) async throws -> UIImage {
        if originalDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: originalDelayNanoseconds)
        }
        return try originalResult.get()
    }
}
