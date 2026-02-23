import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var conversations: [Conversation]

    @StateObject private var viewModel = SettingsViewModel()
    @State private var showDeleteAlert = false
    @State private var exportSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Appearance
                        settingsCard(title: "Appearance", icon: "paintbrush.fill", iconColor: .indigo) {
                            settingRow {
                                Label("Theme", systemImage: "circle.lefthalf.filled")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { appState.settings.appTheme },
                                    set: { appState.settings.appTheme = $0 }
                                )) {
                                    ForEach(AppTheme.allCases) { theme in
                                        Text(theme.rawValue.capitalized).tag(theme)
                                    }
                                }
                                .labelsHidden()
                                .tint(.indigo)
                            }

                            Divider().padding(.leading, 16)

                            settingRow {
                                Label("Font Size", systemImage: "textformat.size")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(Int(appState.settings.messageFontSize))pt")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 13))
                            }
                            Slider(
                                value: Binding(
                                    get: { appState.settings.messageFontSize },
                                    set: { appState.settings.messageFontSize = $0 }
                                ),
                                in: 13...24, step: 1
                            )
                            .tint(.indigo)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 6)

                            Divider().padding(.leading, 16)

                            settingRow {
                                Label("Pattern Background", systemImage: "square.grid.3x3.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { appState.settings.usePatternBackground },
                                    set: { appState.settings.usePatternBackground = $0 }
                                ))
                                .tint(.indigo)
                                .labelsHidden()
                            }
                        }

                        // Chat
                        settingsCard(title: "Chat", icon: "bubble.left.and.bubble.right.fill", iconColor: .teal) {
                            settingRow {
                                Label("Haptic Feedback", systemImage: "hand.tap.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { appState.settings.hapticsEnabled },
                                    set: { appState.settings.hapticsEnabled = $0 }
                                ))
                                .tint(.teal)
                                .labelsHidden()
                            }

                            Divider().padding(.leading, 16)

                            settingRow {
                                Label("Send with Return", systemImage: "return")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { appState.settings.sendWithEnter },
                                    set: { appState.settings.sendWithEnter = $0 }
                                ))
                                .tint(.teal)
                                .labelsHidden()
                            }

                            Divider().padding(.leading, 16)

                            settingRow {
                                Label("Auto Scroll", systemImage: "arrow.down.to.line")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { appState.settings.autoScroll },
                                    set: { appState.settings.autoScroll = $0 }
                                ))
                                .tint(.teal)
                                .labelsHidden()
                            }

                            Divider().padding(.leading, 16)

                            settingRow {
                                Label("Show Timestamps", systemImage: "clock")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { appState.settings.showTimestamps },
                                    set: { appState.settings.showTimestamps = $0 }
                                ))
                                .tint(.teal)
                                .labelsHidden()
                            }
                        }

                        // Data
                        settingsCard(title: "Data", icon: "externaldrive.fill", iconColor: .orange) {
                            Button(action: {
                                let json = viewModel.buildExportJSON(from: conversations)
                                UIPasteboard.general.string = json
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    exportSuccess = true
                                }
                                viewModel.statusMessage = "✅ Copied to clipboard"
                                AppLog.persistence.info("Exported \(conversations.count) conversations")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { exportSuccess = false }
                                }
                            }) {
                                settingRow {
                                    Label("Export as JSON", systemImage: exportSuccess ? "checkmark.circle.fill" : "square.and.arrow.up")
                                        .foregroundStyle(exportSuccess ? .green : .orange)
                                        .animation(.easeInOut(duration: 0.2), value: exportSuccess)
                                    Spacer()
                                    if exportSuccess {
                                        Text("Copied!")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 16)

                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                settingRow {
                                    Label("Delete All Conversations", systemImage: "trash.fill")
                                        .foregroundStyle(.red)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // App info footer
                        VStack(spacing: 4) {
                            Text("ChatPrototipo")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text("Local-first · Private · Made with ❤️")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete All?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) {
                    conversations.forEach(modelContext.delete)
                    try? modelContext.save()
                    viewModel.statusMessage = "All conversations deleted."
                    AppLog.persistence.info("All conversations deleted")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all conversations. This action cannot be undone.")
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func settingsCard<Content: View>(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(iconColor)
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
