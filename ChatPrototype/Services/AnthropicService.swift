import Foundation

final class AnthropicService: LLMService {
    let providerName = "Anthropic"
    let availableModels = ["claude-sonnet-4-20250514", "claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"]

    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) async throws -> String {
        let request = try makeRequest(messages: messages, model: model, systemPrompt: systemPrompt, temperature: temperature, stream: false, maxTokens: maxTokens)
        let (data, _) = try await NetworkManager.shared.send(request: request)
        let decoded = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        return decoded.content.first?.text ?? ""
    }

    func streamMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try makeRequest(messages: messages, model: model, systemPrompt: systemPrompt, temperature: temperature, stream: true, maxTokens: maxTokens)
                    let stream = NetworkManager.shared.stream(request: request, parser: StreamingParser())

                    for try await event in stream {
                        if event.event == "message_stop" {
                            continuation.finish()
                            return
                        }
                        guard let data = event.data.data(using: .utf8),
                              let decoded = try? JSONDecoder().decode(AnthropicStreamEvent.self, from: data),
                              decoded.type == "content_block_delta",
                              let text = decoded.delta?.text,
                              !text.isEmpty
                        else { continue }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func makeRequest(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, stream: Bool, maxTokens: Int) throws -> URLRequest {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { throw AppError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let userMessages = messages.filter { $0.role != "system" }.map { ["role": $0.role, "content": $0.content] }
        let body: [String: Any] = [
            "model": model,
            "messages": userMessages,
            "system": systemPrompt ?? "",
            "stream": stream,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

private struct AnthropicResponse: Decodable {
    struct ContentBlock: Decodable {
        let text: String
    }

    let content: [ContentBlock]
}

private struct AnthropicStreamEvent: Decodable {
    struct Delta: Decodable {
        let text: String?
    }

    let type: String
    let delta: Delta?
}
