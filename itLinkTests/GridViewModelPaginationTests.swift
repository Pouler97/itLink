import XCTest
@testable import itLink

@MainActor
final class GridViewModelPaginationTests: XCTestCase {
    func testFirstPageShowsAtMostPageSize() {
        let viewModel = GridViewModel()
        viewModel.applyItemsForTesting(makeItems(count: 40))

        XCTAssertEqual(viewModel.displayedItems.count, GridViewModel.pageSize)
        XCTAssertEqual(viewModel.items.count, 40)
    }

    func testRevealingLastVisibleItemAppendsNextPage() {
        let viewModel = GridViewModel()
        viewModel.applyItemsForTesting(makeItems(count: 40))

        let firstLast = viewModel.displayedItems.last!
        viewModel.revealMoreIfNeeded(for: firstLast)

        XCTAssertEqual(viewModel.displayedItems.count, GridViewModel.pageSize * 2)
    }

    func testRevealDoesNotGrowWhenItemIsNotLast() {
        let viewModel = GridViewModel()
        viewModel.applyItemsForTesting(makeItems(count: 40))

        viewModel.revealMoreIfNeeded(for: viewModel.displayedItems[0])

        XCTAssertEqual(viewModel.displayedItems.count, GridViewModel.pageSize)
    }

    func testRevealStopsAtTotalCount() {
        let viewModel = GridViewModel()
        viewModel.applyItemsForTesting(makeItems(count: 15))

        viewModel.revealMoreIfNeeded(for: viewModel.displayedItems.last!)

        XCTAssertEqual(viewModel.displayedItems.count, 15)
        viewModel.revealMoreIfNeeded(for: viewModel.displayedItems.last!)
        XCTAssertEqual(viewModel.displayedItems.count, 15)
    }

    func testGalleryUsesFullImageListNotVisiblePage() {
        let viewModel = GridViewModel()
        viewModel.applyItemsForTesting(makeItems(count: 40))

        XCTAssertEqual(viewModel.imageItems.count, 40)
        XCTAssertEqual(viewModel.galleryStartIndex(for: viewModel.items[20]), 20)
    }

    private func makeItems(count: Int) -> [ImageGridItem] {
        (0..<count).map { index in
            ImageGridItem(
                id: "\(index)",
                sourceText: "https://example.com/\(index).jpg",
                kind: .imageURL(URL(string: "https://example.com/\(index).jpg")!)
            )
        }
    }
}
