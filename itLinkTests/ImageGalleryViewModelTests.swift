import XCTest
@testable import itLink

@MainActor
final class ImageGalleryViewModelTests: XCTestCase {
    func testCancelledLoadCanRestartAfterSwipeAway() async {
        let loader = MockImageLoader()
        loader.originalDelayNanoseconds = 1_000_000_000

        let items = [makeImageItem(id: "1"), makeImageItem(id: "2")]
        let viewModel = ImageGalleryViewModel(items: items, startIndex: 0, imageLoader: loader)

        viewModel.onAppear()
        XCTAssertEqual(viewModel.state(for: items[0]), .loading)

        viewModel.cancelAllLoading()
        viewModel.onAppear()
        await waitUntil(viewModel.state(for: items[0]) == .loaded)

        XCTAssertNotNil(viewModel.image(for: items[0]))
    }

    func testRetryDoesNotLetCancelledTaskClearTheNewLoad() async {
        let loader = MockImageLoader()
        loader.originalDelayNanoseconds = 80_000_000
        loader.originalResult = .success(TestImageFactory.solidColor())

        let item = makeImageItem(id: "1")
        let viewModel = ImageGalleryViewModel(items: [item], startIndex: 0, imageLoader: loader)

        viewModel.onAppear()
        loader.originalDelayNanoseconds = 1_000_000_000
        viewModel.retry(item: item)
        XCTAssertEqual(viewModel.state(for: item), .loading)

        try? await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(viewModel.state(for: item), .loading)
    }

    func testSelectIndexLoadsCurrentAndNeighborImages() async {
        let loader = MockImageLoader()
        loader.originalResult = .success(TestImageFactory.solidColor())

        let items = [makeImageItem(id: "1"), makeImageItem(id: "2"), makeImageItem(id: "3")]
        let viewModel = ImageGalleryViewModel(items: items, startIndex: 1, imageLoader: loader)

        viewModel.onAppear()
        await waitUntil(viewModel.pageItems.count == 3)
        await waitUntil(viewModel.state(for: items[1]) == .loaded)
        await waitUntil(viewModel.state(for: items[0]) == .loaded)
        await waitUntil(viewModel.state(for: items[2]) == .loaded)

        XCTAssertEqual(viewModel.state(for: items[1]), .loaded)
        XCTAssertEqual(viewModel.state(for: items[0]), .loaded)
        XCTAssertEqual(viewModel.state(for: items[2]), .loaded)
    }

    func testPagingSkipsItemsWhoseThumbnailFailed() async {
        let loader = MockImageLoader()
        let validA = makeImageItem(id: "1")
        let invalid = makeImageItem(id: "2")
        let validB = makeImageItem(id: "3")

        loader.thumbnailResults = [
            URL(string: "https://example.com/1.jpg")!: .success(TestImageFactory.solidColor()),
            URL(string: "https://example.com/2.jpg")!: .failure(ImageLoadingError.invalidImageData),
            URL(string: "https://example.com/3.jpg")!: .success(TestImageFactory.solidColor())
        ]

        let viewModel = ImageGalleryViewModel(
            items: [validA, invalid, validB],
            startIndex: 0,
            imageLoader: loader
        )

        viewModel.onAppear()
        await waitUntil(viewModel.pageItems.count == 2)

        XCTAssertEqual(viewModel.pageItems.map(\.id), ["1", "3"])
        XCTAssertFalse(viewModel.pageItems.contains(where: { $0.id == "2" }))
    }

    func testRetryAfterFailureReloadsImage() async {
        let loader = MockImageLoader()
        loader.originalResult = .failure(ImageLoadingError.invalidImageData)

        let item = makeImageItem(id: "1")
        let viewModel = ImageGalleryViewModel(items: [item], startIndex: 0, imageLoader: loader)

        viewModel.onAppear()
        await waitUntil(viewModel.state(for: item) == .failed)

        loader.originalResult = .success(TestImageFactory.solidColor())
        viewModel.retry(item: item)
        await waitUntil(viewModel.state(for: item) == .loaded)

        XCTAssertNotNil(viewModel.image(for: item))
    }

    func testGalleryDropsOriginalsOutsideRetentionWindow() async {
        let loader = MockImageLoader()
        loader.originalResult = .success(TestImageFactory.solidColor())

        let items = (1...7).map { makeImageItem(id: "\($0)") }
        let viewModel = ImageGalleryViewModel(items: items, startIndex: 0, imageLoader: loader)

        viewModel.onAppear()
        await waitUntil(viewModel.pageItems.count == 7)
        await waitUntil(viewModel.image(for: items[0]) != nil)

        viewModel.selectIndex(6)
        await waitUntil(viewModel.image(for: items[6]) != nil)
        await waitUntil(viewModel.image(for: items[0]) == nil)

        XCTAssertNil(viewModel.image(for: items[0]))
        XCTAssertNotNil(viewModel.image(for: items[6]))
    }

    private func makeImageItem(id: String) -> ImageGridItem {
        ImageGridItem(
            id: id,
            sourceText: "https://example.com/\(id).jpg",
            kind: .imageURL(URL(string: "https://example.com/\(id).jpg")!)
        )
    }

    private func waitUntil(
        _ condition: @autoclosure () -> Bool,
        timeout: TimeInterval = 2
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(10))
        }
        if !condition() {
            XCTFail("Timed out waiting for condition")
        }
    }
}
