import SwiftData
import SwiftUI
import UIKit

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var viewModel: ChatViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            MessageListView(
                messages: conversation.messages.sorted(by: { $0.timestamp < $1.timestamp }),
                isThinking: viewModel.isThinking,
                showTimestamps: appState.settings.showTimestamps,
                autoScroll: appState.settings.autoScroll,
                messageFontSize: appState.settings.messageFontSize
            )
            if let error = viewModel.errorBanner {
                ErrorBannerView(text: error)
            }
            Divider()
            InputBarView(
                text: $viewModel.inputText,
                isStreaming: viewModel.isStreaming,
                showCounter: true,
                sendWithEnter: appState.settings.sendWithEnter,
                onSend: {
                    viewModel.sendMessage(in: conversation, modelContext: modelContext)
                    if appState.settings.hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                },
                onStop: viewModel.stopStreaming
            )
        }
        .background(backgroundLayer)
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 10) {
            AvatarView()
            VStack(alignment: .leading, spacing: 2) {
                Text("Support Bot")
                    .font(.headline)
                Text(viewModel.isStreaming || viewModel.isThinking ? "Typing..." : "Online")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var backgroundLayer: some View {
        Group {
            if appState.settings.usePatternBackground {
                ZStack {
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    GeometryReader { geo in
                        Path { path in
                            let step: CGFloat = 28
                            var y: CGFloat = 0
                            while y < geo.size.height {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                y += step
                            }
                        }
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    }
                }
            } else {
                Color(.systemBackground)
            }
        }
    }
}

struct MessageListView: View {
    let messages: [Message]
    let isThinking: Bool
    let showTimestamps: Bool
    let autoScroll: Bool
    let messageFontSize: Double

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages, id: \.id) { message in
                        MessageBubbleView(message: message, showTimestamp: showTimestamps, messageFontSize: messageFontSize)
                            .id(message.id)
                            .transition(.asymmetric(insertion: .move(edge: message.isFromUser ? .trailing : .leading).combined(with: .opacity), removal: .opacity))
                    }
                    if isThinking {
                        TypingIndicatorView()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                guard autoScroll, let last = messages.last else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let showTimestamp: Bool
    let messageFontSize: Double

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isFromUser { Spacer(minLength: 30) }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Group {
                    if let attributed = try? AttributedString(markdown: message.text) {
                        Text(attributed)
                    } else {
                        Text(message.text)
                    }
                }
                .font(.system(size: messageFontSize))
                .foregroundStyle(message.isFromUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(message.isFromUser ? AnyShapeStyle(LinearGradient(colors: [.blue, .blue.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color(.systemGray5)))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)

                if showTimestamp {
                    Text(message.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 320, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser { Spacer(minLength: 30) }
        }
    }
}

struct InputBarView: View {
    @Binding var text: String
    let isStreaming: Bool
    let showCounter: Bool
    let sendWithEnter: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type a message", text: $text, axis: .vertical)
                    .lineLimit(1...8)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onSubmit {
                        if sendWithEnter { onSend() }
                    }

                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(canSend ? .blue : .gray)
                            .scaleEffect(canSend ? 1 : 0.95)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: canSend)
                    }
                    .disabled(!canSend)
                }
            }
            if showCounter {
                HStack {
                    Spacer()
                    Text("\(text.count) characters")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct TypingIndicatorView: View {
    var body: some View {
        HStack {
            LoadingDotsView()
                .padding(10)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            Spacer()
        }
    }
}
