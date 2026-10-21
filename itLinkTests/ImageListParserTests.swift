import XCTest
@testable import itLink

final class ImageListParserTests: XCTestCase {
    func testParseClassifiesValidHTTPURLAsImageURL() {
        let items = ImageListParser.parse(content: "https://example.com/a.jpg")

        XCTAssertEqual(items.count, 1)
        guard case .imageURL = items[0].kind else {
            return XCTFail("Expected imageURL kind")
        }
    }

    func testParseClassifiesPlainTextAsNonLink() {
        let items = ImageListParser.parse(content: "lalala")

        XCTAssertEqual(items.count, 1)
        guard case let .nonLink(text) = items[0].kind else {
            return XCTFail("Expected nonLink kind")
        }
        XCTAssertEqual(text, "lalala")
    }

    func testParseSplitsWhitespaceSeparatedTokensOnSameLine() {
        let items = ImageListParser.parse(content: "https://example.com/a.jpg lalala")

        XCTAssertEqual(items.count, 2)
        guard case .imageURL = items[0].kind else {
            return XCTFail("Expected first token to be imageURL")
        }
        guard case .nonLink = items[1].kind else {
            return XCTFail("Expected second token to be nonLink")
        }
    }

    func testParseSkipsEmptyLines() {
        let items = ImageListParser.parse(content: "\n\nhttps://example.com/a.jpg\n")

        XCTAssertEqual(items.count, 1)
    }

    func testParseRejectsNonHTTPSchemes() {
        let items = ImageListParser.parse(content: "ftp://example.com/a.jpg file:///tmp/a.jpg")

        XCTAssertEqual(items.count, 2)
        XCTAssertTrue(items.allSatisfy {
            if case .nonLink = $0.kind { return true }
            return false
        })
    }

    func testParseAssignsStableUniqueIDsPerLineAndToken() {
        let items = ImageListParser.parse(content: "a b\nc")

        XCTAssertEqual(items.map(\.id), ["0-0-a", "0-1-b", "1-0-c"])
    }
}
