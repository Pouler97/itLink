import XCTest
@testable import itLink

final class ImageCacheStoreTests: XCTestCase {
    func testStoresOriginalBytesUnchanged() async throws {
        let (store, _) = makeStore()
        let url = URL(string: "https://example.com/photo.jpg")!
        let original = TestImageFactory.jpegData(width: 80, height: 50)

        try await store.storeOriginalData(original, for: url)

        let cached = await store.originalData(for: url)
        XCTAssertEqual(cached, original)
    }

    func testThumbnailRoundTripFromDisk() async throws {
        let (store, _) = makeStore()
        let url = URL(string: "https://example.com/thumb.jpg")!
        let image = TestImageFactory.solidColor(size: CGSize(width: 32, height: 32))

        try await store.storeThumbnail(image, for: url)

        let cached = await store.thumbnailImage(for: url)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached!.size.width, 32, accuracy: 1)
    }

    private func makeStore() -> (ImageCacheStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("itLink-tests-\(UUID().uuidString)", isDirectory: true)
        let diskCache = DiskCache(rootDirectory: directory)
        return (ImageCacheStore(diskCache: diskCache), directory)
    }
}
