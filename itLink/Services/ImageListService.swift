import Foundation

enum ImageListServiceError: Error {
    case emptyContent
}

actor ImageListService {
    static let shared = ImageListService()

    private let remoteURL = URL(string: "https://it-link.ru/test/images.txt")!
    private let diskCache = DiskCache.shared
    private let httpClient = HTTPClient.shared

    private let listFileName = "images.txt"
    private let listSubdirectory = "manifest"

    func fetchRemoteItems() async throws -> [ImageGridItem] {
        let data = try await httpClient.data(from: remoteURL)
        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            throw ImageListServiceError.emptyContent
        }

        try diskCache.write(data, fileName: listFileName, subdirectory: listSubdirectory)
        return ImageListParser.parse(content: content)
    }

    func cachedItemsIfAvailable() -> [ImageGridItem]? {
        guard let content = loadCachedContent() else { return nil }
        return ImageListParser.parse(content: content)
    }

    private func loadCachedContent() -> String? {
        guard let data = diskCache.read(fileName: listFileName, subdirectory: listSubdirectory) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
