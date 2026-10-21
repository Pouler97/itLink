import Foundation

struct ImageGridItem: Identifiable, Hashable, Sendable {
    let id: String
    let sourceText: String
    let kind: ImageGridItemKind
}

enum ImageGridItemKind: Hashable, Sendable {
    case imageURL(URL)
    case nonLink(text: String)
}

enum ThumbnailLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed
    case placeholder
}
