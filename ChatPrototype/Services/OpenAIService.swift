import Foundation

final class OpenAIService: LLMService {
    let providerName = "OpenAI"
    let availableModels = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]

    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) async throws -> String {
        let request = try makeRequest(messages: messages, model: model, systemPrompt: systemPrompt, temperature: temperature, stream: false, maxTokens: maxTokens)
        let (data, _) = try await NetworkManager.shared.send(request: request)
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }

    func streamMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try makeRequest(messages: messages, model: model, systemPrompt: systemPrompt, temperature: temperature, stream: true, maxTokens: maxTokens)
                    let stream = NetworkManager.shared.stream(request: request, parser: StreamingParser())
                    for try await event in stream {
                        if event.data == "[DONE]" {
                            continuation.finish()
                            return
                        }
                        guard let data = event.data.data(using: .utf8),
                              let decoded = try? JSONDecoder().decode(OpenAIStreamResponse.self, from: data),
                              let delta = decoded.choices.first?.delta.content,
                              !delta.isEmpty
                        else { continue }
                        continuation.yield(delta)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func makeRequest(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, stream: Bool, maxTokens: Int) throws -> URLRequest {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { throw AppError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var payloadMessages: [[String: String]] = []
        if let systemPrompt, !systemPrompt.isEmpty {
            payloadMessages.append(["role": "system", "content": systemPrompt])
        }
        payloadMessages.append(contentsOf: messages.map { ["role": $0.role, "content": $0.content] })

        let body: [String: Any] = [
            "model": model,
            "messages": payloadMessages,
            "stream": stream,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIStreamResponse: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta
    }

    let choices: [Choice]
}
