import SwiftData

enum DataContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Conversation.self, Message.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
