import SwiftUI
import SwiftData

@main
struct ChatPrototypeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataContainer.shared)
    }
}
