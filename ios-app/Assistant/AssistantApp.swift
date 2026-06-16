import SwiftUI
import SwiftData

@main
struct AssistantApp: App {
    let container = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
