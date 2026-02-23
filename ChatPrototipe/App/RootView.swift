import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Conversation.updatedAt, order: .reverse)])
    private var conversations: [Conversation]

    @State private var appState = AppState()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                shell
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .environment(appState)
        .preferredColorScheme(appState.settings.appTheme.colorScheme)
        .sheet(isPresented: Binding(
            get: { appState.showingSettings },
            set: { appState.showingSettings = $0 }
        )) {
            SettingsView()
                .environment(appState)
        }
        .onAppear {
            AppLog.app.info("RootView started")
            ensureConversationExists()
        }
        .onOpenURL { url in
            guard url.scheme == "chatprototipo", url.host == "conversation", let id = UUID(uuidString: url.lastPathComponent) else {
                return
            }
            appState.selectedConversationID = id
        }
    }

    private var shell: some View {
        NavigationSplitView {
            ConversationListView(
                conversations: conversations,
                selectedID: Binding(
                    get: { appState.selectedConversationID },
                    set: { appState.selectedConversationID = $0 }
                ),
                onCreateConversation: createConversation,
                onDeleteConversation: deleteConversation,
                onTogglePin: togglePin
            )
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        authViewModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        } detail: {
            if let selectedID = appState.selectedConversationID,
               let conversation = conversations.first(where: { $0.id == selectedID }) {
                ChatView(conversation: conversation, viewModel: chatViewModel)
                    .environment(appState)
            } else {
                EmptyStateView(title: "No Conversation Selected", subtitle: "Create a new conversation to get started.")
            }
        }
    }

    private func ensureConversationExists() {
        if let first = conversations.first {
            appState.selectedConversationID = first.id
            return
        }
        createConversation()
    }

    private func createConversation() {
        let conversation = Conversation()
        let intro = Message(text: "Hi, I am your support bot. Share how you feel and I will do my best to help.", isFromUser: false, status: .delivered)
        intro.conversation = conversation
        conversation.messages.append(intro)
        modelContext.insert(conversation)
        do {
            try modelContext.save()
            appState.selectedConversationID = conversation.id
            AppLog.persistence.info("Conversation created: \(conversation.id.uuidString, privacy: .public)")
        } catch {
            AppLog.persistence.error("Create conversation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func deleteConversation(_ conversation: Conversation) {
        let willBeEmpty = conversations.filter { $0.id != conversation.id }.isEmpty
        modelContext.delete(conversation)
        do {
            try modelContext.save()
            AppLog.persistence.info("Conversation deleted: \(conversation.id.uuidString, privacy: .public)")
            if appState.selectedConversationID == conversation.id {
                appState.selectedConversationID = conversations.first(where: { $0.id != conversation.id })?.id
            }
            if willBeEmpty {
                createConversation()
            }
        } catch {
            AppLog.persistence.error("Delete conversation failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func togglePin(_ conversation: Conversation) {
        conversation.isPinned.toggle()
        conversation.updatedAt = .now
        do {
            try modelContext.save()
            AppLog.persistence.info("Conversation pin toggled: \(conversation.id.uuidString, privacy: .public)")
        } catch {
            AppLog.persistence.error("Toggle pin failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
