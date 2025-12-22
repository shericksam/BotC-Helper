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
    @Relationship(inverse: \SpecialProperty.parentRole)
    var special: [SpecialProperty]?

    var team: Team? {
        get { teamRaw.flatMap { Team(rawValue: $0) } }
        set { teamRaw = newValue?.rawValue }
    }

    init(
        id: String,
        name: String,
        team: Team? = nil,
        ability: String? = nil,
        setup: Bool? = nil,
        iconName: String? = nil,
        reminders: [String]? = nil,
        remindersGlobal: [String]? = nil,
        firstNightReminder: String? = nil,
        otherNightReminder: String? = nil,
        special: [SpecialProperty]? = nil
    ) {
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
        self.special = special
    }

}
