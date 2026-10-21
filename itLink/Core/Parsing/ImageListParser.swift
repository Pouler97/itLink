import Foundation

enum ImageListParser: Sendable {
    nonisolated static func parse(content: String) -> [ImageGridItem] {
        var items: [ImageGridItem] = []

        for (lineIndex, line) in content.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let tokens = trimmed.split(whereSeparator: \.isWhitespace)
            for (tokenIndex, token) in tokens.enumerated() {
                let text = String(token)
                let id = "\(lineIndex)-\(tokenIndex)-\(text)"

                if let url = validatedURL(from: text) {
                    items.append(ImageGridItem(id: id, sourceText: text, kind: .imageURL(url)))
                } else {
                    items.append(ImageGridItem(id: id, sourceText: text, kind: .nonLink(text: text)))
                }
            }
        }

        return items
    }

    nonisolated private static func validatedURL(from string: String) -> URL? {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
