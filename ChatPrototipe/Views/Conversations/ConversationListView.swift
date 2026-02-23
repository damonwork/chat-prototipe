import SwiftUI

struct ConversationListView: View {
    let conversations: [Conversation]
    @Binding var selectedID: UUID?
    let onCreateConversation: () -> Void
    let onDeleteConversation: (Conversation) -> Void
    let onTogglePin: (Conversation) -> Void

    @StateObject private var viewModel = ConversationListViewModel()

    var body: some View {
        List(selection: $selectedID) {
            if !pinnedConversations.isEmpty {
                Section("Pinned") {
                    rows(for: pinnedConversations)
                }
            }

            Section("Recent") {
                rows(for: recentConversations)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onCreateConversation) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    @ViewBuilder
    private func rows(for items: [Conversation]) -> some View {
        ForEach(items, id: \.id) { conversation in
            ConversationRowView(conversation: conversation)
                .tag(conversation.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDeleteConversation(conversation)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        onTogglePin(conversation)
                    } label: {
                        Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                    }
                    .tint(.orange)
                }
        }
    }

    private var filteredConversations: [Conversation] {
        viewModel.filtered(conversations)
    }

    private var pinnedConversations: [Conversation] {
        filteredConversations.filter(\.isPinned)
    }

    private var recentConversations: [Conversation] {
        filteredConversations.filter { !$0.isPinned }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            Text(conversation.previewText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
