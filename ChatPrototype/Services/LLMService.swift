import Foundation

enum AppError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case streamCancelled
    case authFailed
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Missing API key configuration."
        case .invalidResponse: return "Server returned an invalid response."
        case .streamCancelled: return "Generation was stopped."
        case .authFailed: return "Biometric authentication failed."
        case .invalidCredentials: return "Invalid username or password."
        }
    }
}

struct LLMMessage: Codable {
    let role: String
    let content: String
}

protocol LLMService {
    var providerName: String { get }
    var availableModels: [String] { get }

    func sendMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) async throws -> String
    func streamMessage(messages: [LLMMessage], model: String, systemPrompt: String?, temperature: Double, maxTokens: Int) -> AsyncThrowingStream<String, Error>
}
