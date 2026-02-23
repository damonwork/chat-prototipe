import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func send(request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse {
            AppLog.network.info("HTTP status: \(http.statusCode)")
            if !(200..<300).contains(http.statusCode) {
                throw AppError.invalidResponse
            }
        }
        return (data, response)
    }

    func stream(request: URLRequest, parser: StreamingParser) -> AsyncThrowingStream<SSEEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse {
                        AppLog.stream.info("Streaming status: \(http.statusCode)")
                        guard (200..<300).contains(http.statusCode) else {
                            throw AppError.invalidResponse
                        }
                    }
                    for try await line in bytes.lines {
                        if let event = parser.parseLine(line) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    AppLog.stream.error("Streaming failure: \(error.localizedDescription, privacy: .public)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
