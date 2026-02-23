import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Message.conversation)
    var messages: [Message]

    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.isPinned = false
        self.isArchived = false
        self.messages = []
    }

    var lastMessage: Message? {
        messages.sorted { $0.timestamp < $1.timestamp }.last
    }

    var previewText: String {
        lastMessage?.text ?? "No messages yet"
    }
}
