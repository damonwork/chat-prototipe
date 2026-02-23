import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { appState.settings.appTheme },
                        set: { appState.settings.appTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }

                    Slider(value: Binding(
                        get: { appState.settings.messageFontSize },
                        set: { appState.settings.messageFontSize = $0 }
                    ), in: 13...24, step: 1)
                    Text("Message Font Size: \(Int(appState.settings.messageFontSize))")

                    Toggle("Pattern Background", isOn: Binding(
                        get: { appState.settings.usePatternBackground },
                        set: { appState.settings.usePatternBackground = $0 }
                    ))
                }

                Section("Chat") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { appState.settings.hapticsEnabled },
                        set: { appState.settings.hapticsEnabled = $0 }
                    ))
                    Toggle("Send with Return", isOn: Binding(
                        get: { appState.settings.sendWithEnter },
                        set: { appState.settings.sendWithEnter = $0 }
                    ))
                    Toggle("Auto Scroll", isOn: Binding(
                        get: { appState.settings.autoScroll },
                        set: { appState.settings.autoScroll = $0 }
                    ))
                    Toggle("Show Timestamps", isOn: Binding(
                        get: { appState.settings.showTimestamps },
                        set: { appState.settings.showTimestamps = $0 }
                    ))
                }

                Section("Data") {
                    Button("Export Conversations as JSON") {
                        let json = viewModel.buildExportJSON(from: conversations)
                        UIPasteboard.general.string = json
                        viewModel.statusMessage = "Conversation JSON copied to clipboard."
                        AppLog.persistence.info("Exported \(conversations.count) conversations to clipboard")
                    }

                    Button("Delete All Conversations", role: .destructive) {
                        conversations.forEach(modelContext.delete)
                        do {
                            try modelContext.save()
                            viewModel.statusMessage = "All conversations were deleted."
                            AppLog.persistence.info("All conversations deleted")
                        } catch {
                            viewModel.statusMessage = "Could not delete conversations."
                            AppLog.persistence.error("Delete all failed: \(error.localizedDescription, privacy: .public)")
                        }
                    }

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
