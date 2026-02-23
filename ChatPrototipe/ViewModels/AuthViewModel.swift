import LocalAuthentication
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var errorMessage = ""

    init() {
        if let data = UserDefaults.standard.data(forKey: "session.user"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentUser = profile
            AppLog.auth.info("Session restored for \(profile.username, privacy: .public)")
        }
    }

    var isAuthenticated: Bool { currentUser != nil }

    func register(username: String, password: String) {
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUser.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password."
            return
        }

        let key = "auth.user.\(cleanUser)"
        guard KeychainService.shared.save(password, key: key) else {
            errorMessage = "Could not save user credentials."
            return
        }

        let profile = UserProfile(username: cleanUser, displayName: cleanUser)
        currentUser = profile
        persistSession(profile)
        AppLog.auth.info("User registered: \(cleanUser, privacy: .public)")
    }

    func login(username: String, password: String) {
        let key = "auth.user.\(username)"
        guard let stored = KeychainService.shared.read(key: key), stored == password else {
            errorMessage = AppError.invalidCredentials.localizedDescription
            AppLog.auth.error("Login failed for \(username, privacy: .public)")
            return
        }

        let profile = UserProfile(username: username, displayName: username)
        currentUser = profile
        persistSession(profile)
        AppLog.auth.info("Login success for \(username, privacy: .public)")
    }

    func loginWithBiometrics() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Biometrics are not available on this device."
            return
        }

        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Iniciar sesion")
            guard ok,
                  let data = UserDefaults.standard.data(forKey: "session.user"),
                  let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
            else {
                throw AppError.authFailed
            }
            currentUser = profile
            AppLog.auth.info("Biometric login success")
        } catch {
            errorMessage = error.localizedDescription
            AppLog.auth.error("Biometric login failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "session.user")
        AppLog.auth.info("User logged out")
    }

    private func persistSession(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "session.user")
        }
    }
}
