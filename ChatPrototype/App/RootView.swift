import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Conversation.updatedAt, order: .reverse)])
    private var conversations: [Conversation]

    @State private var appState = AppState()
    @StateObject private var chatViewModel = ChatViewModel()

    var body: some View {
        shell
        .environment(appState)
        .preferredColorScheme(appState.settings.appTheme.colorScheme)
        .sheet(isPresented: Binding(
            get: { appState.showingSettings },
            set: { appState.showingSettings = $0 }
        )) {
            SettingsView()
                .environment(appState)
        }
        .sheet(isPresented: Binding(
            get: { appState.showingProfile },
            set: { appState.showingProfile = $0 }
        )) {
            ProfileSetupView()
                .environment(appState)
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.showingOnboarding },
            set: { appState.showingOnboarding = $0 }
        )) {
            OnboardingFlowView(
                onConfigureProfile: {
                    appState.onboarding.markCompleted()
                    appState.showingOnboarding = false
                    appState.showingProfile = true
                },
                onFinishWithoutProfile: {
                    appState.onboarding.markCompleted()
                    appState.showingOnboarding = false
                }
            )
        }
        .onAppear {
            AppLog.app.info("RootView started")
            ensureConversationExists()
            if appState.onboarding.shouldPresent {
                appState.showingOnboarding = true
            }
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
                        appState.showingProfile = true
                    } label: {
                        ProfileAvatarView(
                            avatarData: appState.profile.profile.avatarData,
                            displayName: appState.profile.profile.displayName,
                            size: 26
                        )
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        appState.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Button(action: createConversation) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .shadow(color: .indigo.opacity(0.35), radius: 6, x: 0, y: 3)
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
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
        // Only auto-select the first conversation on launch — never auto-create
        if let first = conversations.first {
            appState.selectedConversationID = first.id
        }
    }

    private func createConversation() {
        let conversation = Conversation()
        let name = appState.profile.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let introName = name.isEmpty ? "there" : name
        let intro = Message(text: "Hey \(introName)! 👋 I'm your personal support bot. Feel free to share how you're doing — I'm here to listen, motivate, and cheer you on! 🌟", isFromUser: false, status: .delivered)
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
        let deletingID = conversation.id
        let nextConversation = conversations.first(where: { $0.id != deletingID })
        modelContext.delete(conversation)
        do {
            try modelContext.save()
            AppLog.persistence.info("Conversation deleted: \(deletingID.uuidString, privacy: .public)")
            if appState.selectedConversationID == deletingID {
                appState.selectedConversationID = nextConversation?.id
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
