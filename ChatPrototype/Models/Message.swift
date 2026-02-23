import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var isFromUser: Bool
    var timestamp: Date
    var statusRaw: String
    var conversation: Conversation?

    init(text: String, isFromUser: Bool, status: MessageStatus) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = .now
        self.statusRaw = status.rawValue
    }

    var status: MessageStatus {
        get { MessageStatus(rawValue: statusRaw) ?? .sent }
        set { statusRaw = newValue.rawValue }
    }
}
