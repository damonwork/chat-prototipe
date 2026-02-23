import Foundation

struct SSEEvent {
    let data: String
    let event: String?
}

final class StreamingParser {
    private var pendingEvent: String?

    func parseLine(_ line: String) -> SSEEvent? {
        if line.hasPrefix("event:") {
            pendingEvent = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            return nil
        }
        guard line.hasPrefix("data:") else { return nil }
        let rawData = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
        let event = SSEEvent(data: rawData, event: pendingEvent)
        pendingEvent = nil
        return event
    }
}
