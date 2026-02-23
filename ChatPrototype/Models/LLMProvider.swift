import SwiftUI

enum MessageStatus: String, Codable, CaseIterable {
    case sending
    case sent
    case delivered
    case failed
}

enum LLMProvider: String, CaseIterable, Codable, Identifiable {
    case openAI
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
