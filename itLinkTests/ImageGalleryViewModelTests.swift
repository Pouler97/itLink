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

    func testSelectIndexLoadsCurrentAndNeighborImages() async {
        let loader = MockImageLoader()
        loader.originalResult = .success(TestImageFactory.solidColor())

        let items = [makeImageItem(id: "1"), makeImageItem(id: "2"), makeImageItem(id: "3")]
        let viewModel = ImageGalleryViewModel(items: items, startIndex: 1, imageLoader: loader)

        viewModel.onAppear()
        await waitUntil(viewModel.state(for: items[1]) == .loaded)

        XCTAssertEqual(viewModel.state(for: items[1]), .loaded)
        XCTAssertEqual(viewModel.state(for: items[0]), .loaded)
        XCTAssertEqual(viewModel.state(for: items[2]), .loaded)
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
    }
}
