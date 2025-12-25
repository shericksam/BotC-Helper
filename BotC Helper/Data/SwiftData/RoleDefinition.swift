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
    var name: [String: String]
    var teamRaw: String?
    var ability: [String: String]?
    var setup: Bool?
    var reminders: [String: [String]]?
    var remindersGlobal: [String: [String]]?
    var firstNightReminder: [String: String]?
    var otherNightReminder: [String: String]?
    @Relationship(inverse: \EditionData.characters) var editions: [EditionData]

    var team: Team? {
        get { teamRaw.flatMap { Team(rawValue: $0) } }
        set { teamRaw = newValue?.rawValue }
    }

    init(
        id: String,
        name: [String: String],
        team: Team? = nil,
        ability: [String: String]? = nil,
        setup: Bool? = nil,
        reminders: [String: [String]]? = nil,
        remindersGlobal: [String: [String]]? = nil,
        firstNightReminder: [String: String]? = nil,
        otherNightReminder: [String: String]? = nil,
        editions: [EditionData] = []
    ) {
        self.id = id
        self.name = name
        self.teamRaw = team?.rawValue
        self.ability = ability
        self.setup = setup
        self.reminders = reminders
        self.remindersGlobal = remindersGlobal
        self.firstNightReminder = firstNightReminder
        self.otherNightReminder = otherNightReminder
        self.editions = editions
    }

}

extension RoleDefinition {
    static func upsert(
        id: String,
        name: [String: String],
        team: Team?,
        ability: [String: String]?,
        setup: Bool?,
        reminders: [String: [String]]?,
        remindersGlobal: [String: [String]]?,
        firstNightReminder: [String: String]?,
        otherNightReminder: [String: String]?,
        edition: EditionData?,
        modelContext: ModelContext
    ) -> RoleDefinition {

        let fetch = FetchDescriptor<RoleDefinition>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        if let existing = fetched.first {
            if existing.name.isEmpty { existing.name = name }
            if existing.ability == nil || existing.ability?.isEmpty == true { existing.ability = ability }
            if existing.team == nil { existing.team = team }
            if existing.reminders == nil || existing.reminders?.isEmpty == true { existing.reminders = reminders }
            if existing.remindersGlobal == nil || existing.remindersGlobal?.isEmpty == true { existing.remindersGlobal = remindersGlobal }
            if existing.firstNightReminder == nil || existing.firstNightReminder?.isEmpty == true { existing.firstNightReminder = firstNightReminder }
            if existing.otherNightReminder == nil || existing.otherNightReminder?.isEmpty == true { existing.otherNightReminder = otherNightReminder }
            if existing.setup == nil { existing.setup = setup }
            return existing
        } else {
            let new = RoleDefinition(
                id: id,
                name: name,
                team: team,
                ability: ability,
                setup: setup,
                reminders: reminders,
                remindersGlobal: remindersGlobal,
                firstNightReminder: firstNightReminder,
                otherNightReminder: otherNightReminder
            )
            if let edition {
                new.editions.append(edition)
            }
            modelContext.insert(new)
            return new
        }
    }
}

extension RoleDefinition {
    func localizedString(_ dict: [String: String]?) -> String {
        let preferred = Locale.preferredLanguages
            .compactMap { $0.components(separatedBy: "-").first }
        for langCode in preferred {
            if let txt = dict?[langCode], !txt.isEmpty { return txt }
        }
        if let en = dict?["en"], !en.isEmpty { return en }
        if let any = dict?.values.first { return any }
        return ""
    }
    // Para un campo [String: [String]]
    func localizedArray(_ dict: [String: [String]]?) -> [String] {
        let preferred = Locale.preferredLanguages
            .compactMap { $0.components(separatedBy: "-").first }
        for lang in preferred {
            if let arr = dict?[lang], !arr.isEmpty { return arr }
        }
        if let enarr = dict?["en"], !enarr.isEmpty { return enarr }
        if let first = dict?.values.first, !first.isEmpty { return first }
        return []
    }
    func nameLocalized() -> String { localizedString(self.name) }
    func abilityLocalized() -> String { localizedString(self.ability) }
    func firstNightReminderLocalized() -> String { localizedString(self.firstNightReminder) }
    func otherNightReminderLocalized() -> String { localizedString(self.otherNightReminder) }
    func remindersLocalized() -> [String] { localizedArray(self.reminders) }
    func remindersGlobalLocalized() -> [String] { localizedArray(self.remindersGlobal) }
}
