import PhotosUI
import SwiftUI
import UIKit

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var draftName = ""
    @State private var isFocused = false
    @State private var saved = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Avatar + hint section
                    VStack(spacing: 14) {
                        // Avatar circle with "add photo" overlay
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                ProfileAvatarView(
                                    avatarData: appState.profile.profile.avatarData,
                                    displayName: appState.profile.profile.displayName,
                                    size: 88
                                )

                                // Overlay label only when no photo
                                if appState.profile.profile.avatarData == nil {
                                    VStack(spacing: 2) {
                                        Spacer()
                                        Text("add\nphoto")
                                            .font(.system(size: 11, weight: .semibold))
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.indigo)
                                            .padding(.bottom, 10)
                                    }
                                    .frame(width: 88, height: 88)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Description text (like WhatsApp)
                        Text("Enter your name and add an optional profile picture")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 36)
                    .padding(.bottom, 36)

                    // Name field with bottom line only
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            TextField("Your name", text: $draftName)
                                .textInputAutocapitalization(.words)
                                .font(.system(size: 17))
                                .focused($nameFieldFocused)
                                .onSubmit { saveAndDismiss() }

                            if !draftName.isEmpty {
                                Button {
                                    draftName = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                        // Bottom line — indigo when focused, separator otherwise
                        Rectangle()
                            .fill(nameFieldFocused ? Color.indigo : Color(.separator))
                            .frame(height: nameFieldFocused ? 2 : 0.5)
                            .animation(.easeInOut(duration: 0.2), value: nameFieldFocused)
                    }
                    .background(Color(.secondarySystemGroupedBackground))

                    // Remove photo row (only when photo is set)
                    if appState.profile.profile.avatarData != nil {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appState.profile.profile.avatarData = nil
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Remove photo")
                                    .font(.system(size: 15))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                        .background(Color(.secondarySystemGroupedBackground))
                        .padding(.top, 1)
                    }

                    Spacer()

                    // Done button — full width, indigo, capsule
                    let nameIsEmpty = draftName.trimmingCharacters(in: .whitespaces).isEmpty
                    Button(action: saveAndDismiss) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(nameIsEmpty ? Color.secondary : Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background {
                                if nameIsEmpty {
                                    Capsule().fill(Color(.systemFill))
                                } else {
                                    Capsule().fill(LinearGradient(colors: [.indigo, .blue], startPoint: .leading, endPoint: .trailing))
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: nameIsEmpty)
                    }
                    .disabled(nameIsEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        appState.showingProfile = false
                    }
                    .foregroundStyle(.indigo)
                }
            }
            .onAppear {
                draftName = appState.profile.profile.displayName == "You" ? "" : appState.profile.profile.displayName
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    nameFieldFocused = true
                }
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
        }
    }

    private func saveAndDismiss() {
        let clean = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        appState.profile.profile.displayName = clean
        appState.showingProfile = false
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
                .strokeBorder(
                    LinearGradient(colors: [.indigo.opacity(0.5), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: size * 0.04
                )
        )
    }

    private var initials: String {
        let words = displayName.split(separator: " ")
        let firstTwo = words.prefix(2).compactMap { $0.first }
        if firstTwo.isEmpty { return "U" }
        return String(firstTwo).uppercased()
    }
}
