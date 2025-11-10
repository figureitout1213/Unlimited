//
//  JARVIS_GPTApp.swift
//  JARVIS GPT
//
//  Created by Jamison A Lerner on 10/27/25.
//

import SwiftUI
import SwiftData

@main
struct JARVIS_GPTApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])

        let configuration = ModelConfiguration(for: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
