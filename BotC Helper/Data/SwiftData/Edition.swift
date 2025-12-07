//
//  Edition.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
import SwiftData
@Model
final class EditionMeta {
    @Attribute(.unique) var id: String
    var name: String
    var author: String?
    var firstNight: [String]
    var otherNight: [String]

    init(id: String, name: String, author: String?, firstNight: [String], otherNight: [String]) {
        self.id = id
        self.name = name
        self.author = author
        self.firstNight = firstNight
        self.otherNight = otherNight
    }
}

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

    @Model
    final class SpecialProperty {
        var name: String
        var type: String
        var time: String?
        var value: String?

        init(name: String, type: String, time: String? = nil, value: String? = nil) {
            self.name = name
            self.type = type
            self.time = time
            self.value = value
        }
    }
}

@Model
final class EditionData {
    @Relationship(deleteRule: .cascade) var meta: EditionMeta?
    @Relationship(deleteRule: .cascade) var characters: [RoleDefinition] = []

    var id: String { meta?.id ?? UUID().uuidString }

    init(meta: EditionMeta, characters: [RoleDefinition]) {
        self.meta = meta
        self.characters = characters
    }
}
