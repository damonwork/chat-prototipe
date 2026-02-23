import Observation
import Foundation

@Observable
final class SettingsStore {
    var appTheme: AppTheme = .system { didSet { persist() } }
    var messageFontSize: Double = 16 { didSet { persist() } }
    var usePatternBackground: Bool = true { didSet { persist() } }
    var hapticsEnabled: Bool = true { didSet { persist() } }
    var sendWithEnter: Bool = true { didSet { persist() } }
    var autoScroll: Bool = true { didSet { persist() } }
    var showTimestamps: Bool = true { didSet { persist() } }

    private let defaults = UserDefaults.standard

    init() {
        if let rawTheme = defaults.string(forKey: "settings.theme"), let theme = AppTheme(rawValue: rawTheme) {
            appTheme = theme
        }
        messageFontSize = defaults.object(forKey: "settings.messageFontSize") as? Double ?? messageFontSize
        usePatternBackground = defaults.object(forKey: "settings.pattern") as? Bool ?? usePatternBackground
        hapticsEnabled = defaults.object(forKey: "settings.haptics") as? Bool ?? hapticsEnabled
        sendWithEnter = defaults.object(forKey: "settings.sendWithEnter") as? Bool ?? sendWithEnter
        autoScroll = defaults.object(forKey: "settings.autoScroll") as? Bool ?? autoScroll
        showTimestamps = defaults.object(forKey: "settings.showTimestamps") as? Bool ?? showTimestamps
    }

    private func persist() {
        defaults.set(appTheme.rawValue, forKey: "settings.theme")
        defaults.set(messageFontSize, forKey: "settings.messageFontSize")
        defaults.set(usePatternBackground, forKey: "settings.pattern")
        defaults.set(hapticsEnabled, forKey: "settings.haptics")
        defaults.set(sendWithEnter, forKey: "settings.sendWithEnter")
        defaults.set(autoScroll, forKey: "settings.autoScroll")
        defaults.set(showTimestamps, forKey: "settings.showTimestamps")
    }
}

@Observable
final class AppState {
    var selectedConversationID: UUID?
    var settings = SettingsStore()
    var showingSettings = false
}
