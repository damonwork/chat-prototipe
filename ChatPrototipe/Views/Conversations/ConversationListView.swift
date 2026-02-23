import SwiftUI

struct ConversationListView: View {
    let conversations: [Conversation]
    @Binding var selectedID: UUID?
    let onCreateConversation: () -> Void
    let onDeleteConversation: (Conversation) -> Void
    let onTogglePin: (Conversation) -> Void

    @StateObject private var viewModel = ConversationListViewModel()
    @State private var showNewBadge = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    if !pinnedConversations.isEmpty {
                        sectionHeader(title: "📌 Pinned", icon: nil)
                        ForEach(pinnedConversations, id: \.id) { conversation in
                            ConversationRowView(
                                conversation: conversation,
                                isSelected: selectedID == conversation.id,
                                onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selectedID = conversation.id } },
                                onDelete: { onDeleteConversation(conversation) },
                                onTogglePin: { onTogglePin(conversation) }
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                    }

                    sectionHeader(title: "💬 Recent", icon: nil)
                    if recentConversations.isEmpty {
                        emptyState
                    } else {
                        ForEach(recentConversations, id: \.id) { conversation in
                            ConversationRowView(
                                conversation: conversation,
                                isSelected: selectedID == conversation.id,
                                onTap: { withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selectedID = conversation.id } },
                                onDelete: { onDeleteConversation(conversation) },
                                onTogglePin: { onTogglePin(conversation) }
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                    }
                }
                .padding(.bottom, 20)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: conversations.count)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search conversations...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showNewBadge = true
                    }
                    onCreateConversation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showNewBadge = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 30, height: 30)
                            .shadow(color: .indigo.opacity(0.35), radius: 6, x: 0, y: 3)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(showNewBadge ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: showNewBadge)
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String?) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.top, 20)
            Text("No conversations yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Tap + to start a new one")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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

// MARK: - ConversationRowView

struct ConversationRowView: View {
    let conversation: Conversation
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
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
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .contextMenu {
            Button {
                onTogglePin()
            } label: {
                Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: conversation.isPinned ? "pin.slash" : "pin")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onTogglePin) {
                Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: "pin")
            }
            .tint(.orange)
        }
    }

    private var relativeTime: String {
        let diff = Date().timeIntervalSince(conversation.updatedAt)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return conversation.updatedAt.formatted(.dateTime.month(.abbreviated).day())
    }
}
