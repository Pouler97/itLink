import XCTest
@testable import itLink

@MainActor
final class ThumbnailCellViewModelTests: XCTestCase {
    func testCancelLoadingResetsStateToIdle() async {
        let loader = MockImageLoader()
        loader.thumbnailDelayNanoseconds = 1_000_000_000

        let item = makeImageItem()
        let viewModel = ThumbnailCellViewModel(item: item, imageLoader: loader)

        viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loading)

        viewModel.cancelLoading()
        XCTAssertEqual(viewModel.state, .idle)

        viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .loading)
    }

    func testSuccessfulLoadUpdatesStateAndImage() async {
        let loader = MockImageLoader()
        loader.thumbnailResult = .success(TestImageFactory.solidColor())

        let item = makeImageItem()
        let viewModel = ThumbnailCellViewModel(item: item, imageLoader: loader)

        viewModel.loadIfNeeded()
        await waitUntil(viewModel.state == .loaded)

        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testFailedLoadShowsRetryableState() async {
        let loader = MockImageLoader()
        loader.thumbnailResult = .failure(ImageLoadingError.invalidImageData)

        let item = makeImageItem()
        let viewModel = ThumbnailCellViewModel(item: item, imageLoader: loader)

        viewModel.loadIfNeeded()
        await waitUntil(viewModel.state == .failed)

        XCTAssertEqual(viewModel.state, .failed)
        XCTAssertNil(viewModel.image)
    }

    private func makeImageItem() -> ImageGridItem {
        ImageGridItem(
            id: "0-0-test",
            sourceText: "https://example.com/a.jpg",
            kind: .imageURL(URL(string: "https://example.com/a.jpg")!)
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
