import SwiftUI

@main
struct JARVIS_GPTApp: App {
    @StateObject private var store = SubmittableStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
