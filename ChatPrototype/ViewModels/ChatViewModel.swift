import SwiftData
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var isStreaming = false
    @Published var isThinking = false
    @Published var streamingText = ""
    @Published var errorBanner: String?

    private var streamingTask: Task<Void, Never>?

    func sendMessage(in conversation: Conversation, modelContext: ModelContext) {
        let cleanText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        AppLog.ui.info("User sends message. Length: \(cleanText.count)")
        inputText = ""
        isThinking = true
        errorBanner = nil

        let userMessage = Message(text: cleanText, isFromUser: true, status: .sent)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        conversation.updatedAt = .now

        if conversation.title == "New Conversation" {
            conversation.title = String(cleanText.prefix(32))
        }

        let botMessage = Message(text: "", isFromUser: false, status: .sending)
        botMessage.conversation = conversation
        conversation.messages.append(botMessage)

        persist(modelContext)

        streamingTask?.cancel()
        streamingTask = Task { [weak self] in
            guard let self else { return }

            do {
                isStreaming = true
                isThinking = true
                streamingText = ""

                try await Task.sleep(nanoseconds: 350_000_000)
                let fullReply = BotResponseService.shared.buildReply(for: cleanText)
                let chunks = makeChunks(from: fullReply)
                for chunk in chunks {
                    if Task.isCancelled { throw AppError.streamCancelled }
                    try await Task.sleep(nanoseconds: 60_000_000)
                    if isThinking { isThinking = false }
                    streamingText += chunk
                    botMessage.text = streamingText
                    botMessage.status = .delivered
                    conversation.updatedAt = .now
                }

                if botMessage.text.isEmpty {
                    botMessage.text = "No content was produced."
                }
                botMessage.status = .delivered
                AppLog.stream.info("Stream finished. Total chars: \(botMessage.text.count)")
                persist(modelContext)
            } catch {
                botMessage.status = .failed
                botMessage.text = botMessage.text.isEmpty ? "An error happened while generating the reply." : botMessage.text
                errorBanner = error.localizedDescription
                AppLog.stream.error("Stream error: \(error.localizedDescription, privacy: .public)")
                persist(modelContext)
            }

            isThinking = false
            isStreaming = false
            streamingText = ""
        }
    }

    private func makeChunks(from text: String) -> [String] {
        let words = text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [text] }
        return words.enumerated().map { index, word in
            index == words.count - 1 ? word : "\(word) "
        }
    }

    func stopStreaming() {
        AppLog.stream.info("Stop streaming requested")
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
        isThinking = false
    }

    private func persist(_ context: ModelContext) {
        do {
            try context.save()
            AppLog.persistence.info("Context saved")
        } catch {
            AppLog.persistence.error("Save failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
