import XCTest
@testable import itLink

final class ImageLoadingServiceTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testThumbnailStoresOriginalBytesAndDoesNotReencode() async throws {
        let jpeg = TestImageFactory.jpegData(width: 240, height: 180)
        let url = URL(string: "https://example.com/original.jpg")!
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jpeg)
        }

        let (loader, store) = makeLoader()
        let thumbnail = try await loader.thumbnail(for: url)

        let pixelSide = max(thumbnail.size.width * thumbnail.scale, thumbnail.size.height * thumbnail.scale)
        let storedOriginal = await store.originalData(for: url)
        XCTAssertLessThanOrEqual(pixelSide, CGFloat(ImageIODecoder.thumbnailMaxPixelSize) + 1)
        XCTAssertEqual(storedOriginal, jpeg)
        XCTAssertEqual(requestCount, 1)

        _ = try await loader.originalImage(for: url)
        XCTAssertEqual(requestCount, 1)
    }

    func testSecondLoadReadsOriginalFromDiskWithoutNetwork() async throws {
        let jpeg = TestImageFactory.jpegData(width: 60, height: 40)
        let url = URL(string: "https://example.com/cached.jpg")!
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, jpeg)
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("itLink-tests-\(UUID().uuidString)", isDirectory: true)
        let diskCache = DiskCache(rootDirectory: directory)

        let first = makeLoader(diskCache: diskCache)
        _ = try await first.loader.thumbnail(for: url)
        XCTAssertEqual(requestCount, 1)

        let second = makeLoader(diskCache: diskCache)
        _ = try await second.loader.originalImage(for: url)
        XCTAssertEqual(requestCount, 1)
    }

    func testInvalidPayloadIsNotCachedAndCanBeRetried() async throws {
        let url = URL(string: "https://example.com/missing")!
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            )!
            return (response, Data("<html>404</html>".utf8))
        }

        let (loader, store) = makeLoader()

        do {
            _ = try await loader.thumbnail(for: url)
            XCTFail("Expected invalid image data")
        } catch ImageLoadingError.invalidImageData {
            let storedOriginal = await store.originalData(for: url)
            XCTAssertNil(storedOriginal)
        }

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, TestImageFactory.jpegData(width: 20, height: 20))
        }

        let image = try await loader.thumbnail(for: url)
        XCTAssertNotNil(image)
        XCTAssertEqual(requestCount, 2)
    }

    private func makeLoader(
        diskCache: DiskCache? = nil
    ) -> (loader: ImageLoadingService, store: ImageCacheStore) {
        let cache = diskCache ?? DiskCache(
            rootDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("itLink-tests-\(UUID().uuidString)", isDirectory: true)
        )
        let store = ImageCacheStore(diskCache: cache)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let client = HTTPClient(session: URLSession(configuration: configuration))
        let loader = ImageLoadingService(
            httpClient: client,
            cacheStore: store,
            maxConcurrentDownloads: 2
        )
        return (loader, store)
    }
}
