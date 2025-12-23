//
//  RoleDefinition.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class RoleDefinition {
    @Attribute(.unique) var id: String
    var name: String
    var teamRaw: String?
    var ability: String?
    var setup: Bool?
    var iconName: String?
    var reminders: [String]?
    var remindersGlobal: [String]?
    var firstNightReminder: String?
    var otherNightReminder: String?

    var team: Team? {
        get { teamRaw.flatMap { Team(rawValue: $0) } }
        set { teamRaw = newValue?.rawValue }
    }

    init(id: String,
         name: String,
         team: Team? = nil,
         ability: String? = nil,
         setup: Bool? = nil,
         iconName: String? = nil,
         reminders: [String]? = nil,
         remindersGlobal: [String]? = nil,
         firstNightReminder: String? = nil,
         otherNightReminder: String? = nil) {
        self.id = id
        self.name = name
        self.teamRaw = team?.rawValue
        self.ability = ability
        self.setup = setup
        self.iconName = iconName ?? id.replacingOccurrences(of: "secta_", with: "")
        self.reminders = reminders
        self.remindersGlobal = remindersGlobal
        self.firstNightReminder = firstNightReminder
        self.otherNightReminder = otherNightReminder
    }

}

extension RoleDefinition {
    static func upsert(
        id: String,
        name: String,
        team: Team?,
        ability: String?,
        setup: Bool?,
        iconName: String?,
        reminders: [String]?,
        remindersGlobal: [String]?,
        firstNightReminder: String?,
        otherNightReminder: String?,
        modelContext: ModelContext
    ) -> RoleDefinition {

        // Buscar uno existente
        let fetch = FetchDescriptor<RoleDefinition>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        if let existing = fetched.first {
            // Actualiza solo campos que no estén completos
            if existing.name.isEmpty { existing.name = name }
            if existing.ability == nil || existing.ability?.isEmpty == true { existing.ability = ability }
            if existing.team == nil { existing.team = team }
            if existing.iconName == nil || existing.iconName?.isEmpty == true { existing.iconName = iconName }
            if existing.reminders == nil || existing.reminders?.isEmpty == true { existing.reminders = reminders }
            if existing.remindersGlobal == nil || existing.remindersGlobal?.isEmpty == true { existing.remindersGlobal = remindersGlobal }
            if existing.firstNightReminder == nil || existing.firstNightReminder?.isEmpty == true { existing.firstNightReminder = firstNightReminder }
            if existing.otherNightReminder == nil || existing.otherNightReminder?.isEmpty == true { existing.otherNightReminder = otherNightReminder }
            if existing.setup == nil { existing.setup = setup }
            modelContext.insert(existing)
            return existing
        } else {
            let new = RoleDefinition(
                id: id,
                name: name,
                team: team,
                ability: ability,
                setup: setup,
                iconName: iconName,
                reminders: reminders,
                remindersGlobal: remindersGlobal,
                firstNightReminder: firstNightReminder,
                otherNightReminder: otherNightReminder
            )
            modelContext.insert(new)
            return new
        }
    }
}
