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
                Section {
                    rows(for: pinnedConversations)
                } header: {
                    sectionHeader("📌 Pinned")
                }
            }

            Section {
                rows(for: recentConversations)
            } header: {
                sectionHeader("💬 Recent")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .searchable(text: $viewModel.searchText, prompt: "Search conversations...")
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: conversations.count)
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    // MARK: - Rows

    @ViewBuilder
    private func rows(for items: [Conversation]) -> some View {
        if items.isEmpty {
            emptyRow
        } else {
            ForEach(items, id: \.id) { conversation in
                ConversationRowView(
                    conversation: conversation,
                    isSelected: selectedID == conversation.id
                )
                .tag(conversation.id)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                .contextMenu {
                    Button {
                        onTogglePin(conversation)
                    } label: {
                        Label(
                            conversation.isPinned ? "Unpin" : "Pin",
                            systemImage: conversation.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        onDeleteConversation(conversation)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No conversations yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Tap + to start a new one")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    // MARK: - Filtering

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

// MARK: - ConversationRowView

struct ConversationRowView: View {
    let conversation: Conversation
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon bubble
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.systemGray5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 46, height: 46)
                    .shadow(color: isSelected ? .indigo.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)

                Image(systemName: conversation.isPinned ? "pin.fill" : "bubble.left.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? .indigo : .primary)
                        .lineLimit(1)
                    Spacer()
                    Text(relativeTime)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Text(conversation.previewText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.indigo.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.indigo.opacity(0.25) : Color.clear, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        .contentShape(Rectangle())
    }

    private var relativeTime: String {
        let diff = Date().timeIntervalSince(conversation.updatedAt)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return conversation.updatedAt.formatted(.dateTime.month(.abbreviated).day())
    }
}
