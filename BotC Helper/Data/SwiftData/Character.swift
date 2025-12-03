//
//  Character.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
import SwiftData

@Model
final class Character {
    @Attribute(.unique) var id: String
    var name: String
    var team: String?
    var ability: String?
    var setup: Bool
    var images: [String]      // Array de URLs
    var reminders: [String]?
    var firstNightReminder: String?
    var otherNightReminder: String?

    // Puedes añadir más campos especiales según tus necesidades

    init(id: String, name: String, team: String?, ability: String?, setup: Bool = false, images: [String], reminders: [String]? = nil, firstNightReminder: String? = nil, otherNightReminder: String? = nil) {
        self.id = id
        self.name = name
        self.team = team
        self.ability = ability
        self.setup = setup
        self.images = images
        self.reminders = reminders
        self.firstNightReminder = firstNightReminder
        self.otherNightReminder = otherNightReminder
    }
}
