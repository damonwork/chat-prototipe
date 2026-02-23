import Foundation

enum LLMServiceFactory {
    static func make(provider: LLMProvider) throws -> LLMService {
        switch provider {
        case .openAI:
            guard let key = KeychainService.shared.read(key: "openai.api.key"), !key.isEmpty else { throw AppError.missingAPIKey }
            return OpenAIService(apiKey: key)
        case .anthropic:
            guard let key = KeychainService.shared.read(key: "anthropic.api.key"), !key.isEmpty else { throw AppError.missingAPIKey }
            return AnthropicService(apiKey: key)
        }
    }
}
