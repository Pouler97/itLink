import UIKit

protocol ImageLoadingProviding: Sendable {
    func thumbnail(for url: URL) async throws -> UIImage
    func originalImage(for url: URL) async throws -> UIImage
}

extension ImageLoadingService: ImageLoadingProviding {}
