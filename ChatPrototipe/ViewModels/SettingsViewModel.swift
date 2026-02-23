import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var statusMessage = ""

    func buildExportJSON(from conversations: [Conversation]) -> String {
        let payload = conversations.map { conversation in
            [
                "id": conversation.id.uuidString,
                "title": conversation.title,
                "createdAt": ISO8601DateFormatter().string(from: conversation.createdAt),
                "updatedAt": ISO8601DateFormatter().string(from: conversation.updatedAt),
                "isPinned": conversation.isPinned,
                "messages": conversation.messages
                    .sorted(by: { $0.timestamp < $1.timestamp })
                    .map {
                        [
                            "id": $0.id.uuidString,
                            "text": $0.text,
                            "isFromUser": $0.isFromUser,
                            "timestamp": ISO8601DateFormatter().string(from: $0.timestamp),
                            "status": $0.status.rawValue
                        ]
                    }
            ]
        }

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }
}
