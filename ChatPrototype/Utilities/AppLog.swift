import OSLog

enum AppLog {
    static let app = Logger(subsystem: "com.chatprototipo.app", category: "app")
    static let auth = Logger(subsystem: "com.chatprototipo.app", category: "auth")
    static let persistence = Logger(subsystem: "com.chatprototipo.app", category: "persistence")
    static let network = Logger(subsystem: "com.chatprototipo.app", category: "network")
    static let stream = Logger(subsystem: "com.chatprototipo.app", category: "stream")
    static let ui = Logger(subsystem: "com.chatprototipo.app", category: "ui")
}
