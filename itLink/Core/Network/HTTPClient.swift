import Foundation

enum HTTPClientError: Error {
    case invalidResponse
    case httpStatus(Int)
    case noData
}

actor HTTPClient {
    static let shared = HTTPClient()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(
        from url: URL,
        maxRetries: Int = 3,
        retryDelayNanoseconds: UInt64 = 500_000_000
    ) async throws -> Data {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: retryDelayNanoseconds * UInt64(attempt))
            }

            do {
                let (data, response) = try await session.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPClientError.invalidResponse
                }
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw HTTPClientError.httpStatus(httpResponse.statusCode)
                }
                guard !data.isEmpty else {
                    throw HTTPClientError.noData
                }
                return data
            } catch {
                lastError = error
                if error is CancellationError { throw error }
                if !Self.isRetryable(error) { throw error }
            }
        }

        throw lastError ?? HTTPClientError.noData
    }

    nonisolated static func isRetryable(_ error: Error) -> Bool {
        if error is CancellationError { return false }

        if let httpError = error as? HTTPClientError {
            switch httpError {
            case .httpStatus(let code):
                return (500...599).contains(code)
            case .invalidResponse, .noData:
                return true
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return false
            default:
                return true
            }
        }

        return true
    }
}
