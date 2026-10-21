import UIKit

protocol ImageLoadingProviding: Sendable {
    func thumbnail(for url: URL) async throws -> UIImage
    func originalImage(for url: URL) async throws -> UIImage
    func cachedThumbnail(for url: URL) async -> UIImage?
}

extension ImageLoadingService: ImageLoadingProviding {}
