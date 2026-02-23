import PhotosUI
import SwiftUI
import UIKit

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    HStack(spacing: 12) {
                        ProfileAvatarView(avatarData: appState.profile.profile.avatarData, displayName: appState.profile.profile.displayName, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your profile")
                                .font(.headline)
                            Text("Everything stays local on this device")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    TextField("Display name", text: $draftName)
                        .textInputAutocapitalization(.words)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                    }

                    if appState.profile.profile.avatarData != nil {
                        Button("Remove photo", role: .destructive) {
                            appState.profile.profile.avatarData = nil
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveDraftName()
                        appState.showingProfile = false
                    }
                }
            }
            .onAppear {
                draftName = appState.profile.profile.displayName
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        appState.profile.profile.avatarData = data
                    }
                }
            }
            .onChange(of: draftName) { _, _ in
                saveDraftName()
            }
        }
    }

    private func saveDraftName() {
        let clean = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        appState.profile.profile.displayName = clean.isEmpty ? "You" : clean
    }
}

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
                Circle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        Text(initials)
                            .font(.system(size: size * 0.35, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initials: String {
        let words = displayName.split(separator: " ")
        let firstTwo = words.prefix(2).compactMap { $0.first }
        if firstTwo.isEmpty { return "U" }
        return String(firstTwo).uppercased()
    }
}
