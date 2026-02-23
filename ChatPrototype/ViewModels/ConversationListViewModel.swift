import Foundation

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var searchText = ""

    func filtered(_ conversations: [Conversation]) -> [Conversation] {
        guard !searchText.isEmpty else { return conversations.filter { !$0.isArchived } }
        return conversations.filter {
            !$0.isArchived && (
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.messages.contains { $0.text.localizedCaseInsensitiveContains(searchText) }
            )
        }
    }
}
