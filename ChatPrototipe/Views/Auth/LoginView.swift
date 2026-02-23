import PhotosUI
import SwiftUI
import UIKit

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var draftName = ""
    @State private var headerScale = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Soft gradient background
                LinearGradient(
                    colors: [Color.indigo.opacity(0.06), Color(.systemGroupedBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Avatar hero section
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                ProfileAvatarView(
                                    avatarData: appState.profile.profile.avatarData,
                                    displayName: appState.profile.profile.displayName,
                                    size: 100
                                )
                                .shadow(color: .indigo.opacity(0.3), radius: 16, x: 0, y: 8)
                                .scaleEffect(headerScale ? 1.0 : 0.85)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: headerScale)

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }

                            Text(appState.profile.profile.displayName.isEmpty ? "Your Name" : appState.profile.profile.displayName)
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(appState.profile.profile.displayName.isEmpty ? .secondary : .primary)
                                .animation(.easeInOut(duration: 0.2), value: appState.profile.profile.displayName)

                            Text("Everything stays on your device 🔒")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 24)

                        // Form card
                        VStack(spacing: 0) {
                            formRow(icon: "person.fill", iconColor: .indigo) {
                                TextField("Display name", text: $draftName)
                                    .textInputAutocapitalization(.words)
                                    .font(.system(size: 15))
                            }

                            Divider().padding(.leading, 52)

                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                formRow(icon: "photo.fill", iconColor: .teal) {
                                    Text("Choose photo")
                                        .foregroundStyle(.primary)
                                        .font(.system(size: 15))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            if appState.profile.profile.avatarData != nil {
                                Divider().padding(.leading, 52)
                                Button(role: .destructive) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        appState.profile.profile.avatarData = nil
                                    }
                                } label: {
                                    formRow(icon: "trash.fill", iconColor: .red) {
                                        Text("Remove photo")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 15))
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        appState.showingProfile = false
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        saveDraftName()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            saved = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            appState.showingProfile = false
                        }
                    }) {
                        Label("Done", systemImage: saved ? "checkmark" : "")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.indigo)
                            .animation(.easeInOut(duration: 0.2), value: saved)
                    }
                }
            }
            .onAppear {
                draftName = appState.profile.profile.displayName
                withAnimation { headerScale = true }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            appState.profile.profile.avatarData = data
                        }
                    }
                }
            }
            .onChange(of: draftName) { _, _ in
                saveDraftName()
            }
        }
    }

    @ViewBuilder
    private func formRow<Content: View>(icon: String, iconColor: Color, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func saveDraftName() {
        let clean = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.profile.profile.displayName = clean.isEmpty ? "You" : clean
    }
}

// MARK: - ProfileAvatarView

struct ProfileAvatarView: View {
    let avatarData: Data?
    let displayName: String
    var size: CGFloat = 32

    var body: some View {
        Group {
            if let avatarData, let image = UIImage(data: avatarData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.indigo, .blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(initials)
                        .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.white.opacity(0.35), lineWidth: size * 0.03)
        )
    }

    private var initials: String {
        let words = displayName.split(separator: " ")
        let firstTwo = words.prefix(2).compactMap { $0.first }
        if firstTwo.isEmpty { return "U" }
        return String(firstTwo).uppercased()
    }
}
