//
//  BotC_HelperApp.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 02/12/25.
//

import SwiftUI
import SwiftData

@main
struct BotC_HelperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BoardState.self,
            Player.self,
            GameDay.self,
            PlayerStatus.self,
            PersonalNote.self,
            EditionData.self,
            EditionMeta.self,
            RoleDefinition.self,
            SpecialProperty.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }

}
