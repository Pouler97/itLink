import XCTest
@testable import itLink

final class ImageIODecoderTests: XCTestCase {
    func testThumbnailFitsMaxPixelSize() {
        let data = TestImageFactory.jpegData(width: 800, height: 600)

        let thumbnail = ImageIODecoder.thumbnail(from: data, maxPixelSize: 100)

        XCTAssertNotNil(thumbnail)
        let pixelWidth = thumbnail!.size.width * thumbnail!.scale
        let pixelHeight = thumbnail!.size.height * thumbnail!.scale
        XCTAssertLessThanOrEqual(max(pixelWidth, pixelHeight), 100 + 1)
        XCTAssertGreaterThan(min(pixelWidth, pixelHeight), 70)
    }

    func testDisplayImageDoesNotUpscaleSmallSource() {
        let data = TestImageFactory.jpegData(width: 40, height: 30)

        let image = ImageIODecoder.displayImage(from: data, maxPixelSize: 4096)

        XCTAssertNotNil(image)
        XCTAssertEqual(image!.size.width * image!.scale, 40, accuracy: 1)
        XCTAssertEqual(image!.size.height * image!.scale, 30, accuracy: 1)
    }

    func testRejectsNonImageData() {
        let html = Data("<html>not an image</html>".utf8)

        XCTAssertFalse(ImageIODecoder.isDecodableImage(html))
        XCTAssertNil(ImageIODecoder.thumbnail(from: html))
        XCTAssertNil(ImageIODecoder.displayImage(from: html))
    }
}
