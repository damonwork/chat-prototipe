import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isRegister = false

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("ChatPrototipo")
                    .font(.largeTitle.bold())
                Text("Sign in to continue")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            Button(isRegister ? "Create account" : "Sign in") {
                if isRegister {
                    viewModel.register(username: username, password: password)
                } else {
                    viewModel.login(username: username, password: password)
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("Use Face ID / Touch ID") {
                Task { await viewModel.loginWithBiometrics() }
            }
            .buttonStyle(.bordered)

            Button(isRegister ? "I already have an account" : "Create account") {
                isRegister.toggle()
            }
            .font(.subheadline)

            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }
}

struct RegisterView: View {
    var body: some View {
        EmptyStateView(title: "Register", subtitle: "Registration is integrated in LoginView")
    }
}

struct ProfileView: View {
    let user: UserProfile

    var body: some View {
        VStack(spacing: 10) {
            AvatarView()
            Text(user.displayName).font(.headline)
            Text(user.username).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
