import XCTest
@testable import itLink

final class HTTPClientRetryTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testIsRetryableReturnsFalseForHTTP404() {
        XCTAssertFalse(HTTPClient.isRetryable(HTTPClientError.httpStatus(404)))
    }

    func testIsRetryableReturnsTrueForHTTP503() {
        XCTAssertTrue(HTTPClient.isRetryable(HTTPClientError.httpStatus(503)))
    }

    func testIsRetryableReturnsFalseForCancellation() {
        XCTAssertFalse(HTTPClient.isRetryable(CancellationError()))
    }

    func testIsRetryableReturnsFalseForTimeout() {
        XCTAssertFalse(HTTPClient.isRetryable(URLError(.timedOut)))
    }

    func testIsRetryableReturnsFalseForOfflineAndDNSErrors() {
        XCTAssertFalse(HTTPClient.isRetryable(URLError(.notConnectedToInternet)))
        XCTAssertFalse(HTTPClient.isRetryable(URLError(.cannotFindHost)))
        XCTAssertFalse(HTTPClient.isRetryable(URLError(.dnsLookupFailed)))
    }

    func testDoesNotRetryClientErrors() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { _ in
            requestCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("missing".utf8))
        }

        let client = makeClient()

        do {
            _ = try await client.data(
                from: URL(string: "https://example.com/test")!,
                maxRetries: 3,
                retryDelayNanoseconds: 1
            )
            XCTFail("Expected HTTP 404")
        } catch HTTPClientError.httpStatus(404) {
            XCTAssertEqual(requestCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRetriesServerErrorsUpToMaxAttempts() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { _ in
            requestCount += 1
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/test")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("busy".utf8))
        }

        let client = makeClient()

        do {
            _ = try await client.data(
                from: URL(string: "https://example.com/test")!,
                maxRetries: 3,
                retryDelayNanoseconds: 1
            )
            XCTFail("Expected HTTP 503")
        } catch HTTPClientError.httpStatus(503) {
            XCTAssertEqual(requestCount, 3)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testReturnsDataOnSuccessfulRetry() async throws {
        var requestCount = 0
        MockURLProtocol.requestHandler = { _ in
            requestCount += 1
            let url = URL(string: "https://example.com/test")!
            if requestCount == 1 {
                let response = HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil)!
                return (response, Data("busy".utf8))
            }

            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("ok".utf8))
        }

        let client = makeClient()
        let data = try await client.data(
            from: URL(string: "https://example.com/test")!,
            maxRetries: 3,
            retryDelayNanoseconds: 1
        )

        XCTAssertEqual(String(data: data, encoding: .utf8), "ok")
        XCTAssertEqual(requestCount, 2)
    }

    private func makeClient() -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return HTTPClient(session: URLSession(configuration: configuration))
    }
}
