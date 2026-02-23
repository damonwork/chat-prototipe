import SwiftData
import SwiftUI
import UIKit

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var viewModel: ChatViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var headerPulse = false

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer.ignoresSafeArea()

            VStack(spacing: 0) {
                header
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
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .shadow(color: .indigo.opacity(0.4), radius: headerPulse ? 10 : 4, x: 0, y: 0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: headerPulse)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Support Bot")
                    .font(.system(size: 15, weight: .semibold))
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isStreaming || viewModel.isThinking ? Color.orange : Color.green)
                        .frame(width: 7, height: 7)
                        .scaleEffect(viewModel.isStreaming || viewModel.isThinking ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: viewModel.isStreaming || viewModel.isThinking)

                    Text(viewModel.isStreaming || viewModel.isThinking ? "Typing..." : "Online")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.5)
        }
        .onAppear { headerPulse = true }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Group {
            if appState.settings.usePatternBackground {
                ZStack {
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    GeometryReader { geo in
                        Canvas { context, size in
                            let step: CGFloat = 32
                            var y: CGFloat = 0
                            while y < size.height {
                                var path = Path()
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                                context.stroke(path, with: .color(.primary.opacity(0.03)), lineWidth: 1)
                                y += step
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            } else {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground).opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - MessageListView

struct MessageListView: View {
    let messages: [Message]
    let isThinking: Bool
    let showTimestamps: Bool
    let autoScroll: Bool
    let messageFontSize: Double

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages, id: \.id) { message in
                        MessageBubbleView(
                            message: message,
                            showTimestamp: showTimestamps,
                            messageFontSize: messageFontSize
                        )
                        .id(message.id)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85, anchor: message.isFromUser ? .bottomTrailing : .bottomLeading)
                                    .combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                    }
                    if isThinking {
                        TypingIndicatorView()
                            .transition(.asymmetric(insertion: .scale(scale: 0.85, anchor: .bottomLeading).combined(with: .opacity), removal: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: messages.count)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isThinking)
            }
            .onChange(of: messages.count) { _, _ in
                guard autoScroll, let last = messages.last else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: isThinking) { _, thinking in
                if thinking, let last = messages.last {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// MARK: - MessageBubbleView

struct MessageBubbleView: View {
    let message: Message
    let showTimestamp: Bool
    let messageFontSize: Double

    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 50)
            } else {
                botAvatar
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                bubbleContent
                if showTimestamp {
                    Text(message.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: 300, alignment: message.isFromUser ? .trailing : .leading)

            if message.isFromUser {
                // no avatar on right side
            } else {
                Spacer(minLength: 50)
            }
        }
        .scaleEffect(appeared ? 1 : 0.88)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72).delay(0.05)) {
                appeared = true
            }
        }
    }

    private var botAvatar: some View {
        Circle()
            .fill(LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 28, height: 28)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .indigo.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var bubbleContent: some View {
        Group {
            if let attributed = try? AttributedString(markdown: message.text) {
                Text(attributed)
            } else {
                Text(message.text)
            }
        }
        .font(.system(size: messageFontSize))
        .foregroundStyle(message.isFromUser ? .white : .primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bubbleBackground)
        .clipShape(BubbleShape(isFromUser: message.isFromUser))
        .shadow(color: message.isFromUser ? .indigo.opacity(0.2) : .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if message.isFromUser {
            LinearGradient(
                colors: [Color.indigo, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - BubbleShape (iMessage-like tail)

struct BubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromUser {
            // Rounded rect with bottom-right tail
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY - tailSize), control: CGPoint(x: rect.maxX, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        } else {
            // Rounded rect with bottom-left tail
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius - tailSize), control: CGPoint(x: rect.minX, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - InputBarView

struct InputBarView: View {
    @Binding var text: String
    let isStreaming: Bool
    let showCounter: Bool
    let sendWithEnter: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @FocusState private var isFocused: Bool
    @State private var buttonScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.4)
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Message...", text: $text, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(
                                        isFocused
                                            ? LinearGradient(colors: [.indigo.opacity(0.6), .blue.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .focused($isFocused)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                    .onSubmit {
                        if sendWithEnter { onSend() }
                    }

                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.red)
                            .scaleEffect(buttonScale)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                            buttonScale = 1.1
                        }
                    }
                } else {
                    Button(action: {
                        onSend()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                            buttonScale = 1.2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                buttonScale = 1.0
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    canSend
                                        ? LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color(.systemGray4)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: canSend ? .indigo.opacity(0.4) : .clear, radius: 6, x: 0, y: 3)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(buttonScale)
                    }
                    .disabled(!canSend)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: canSend)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - TypingIndicatorView

struct TypingIndicatorView: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                )

            LoadingDotsView()
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            Spacer()
        }
    }
}
