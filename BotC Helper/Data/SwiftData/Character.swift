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
    var name: [String: String]
    var teamRaw: String?
    var ability: [String: String]?
    var reminders: [String: [String]]?
    var firstNightReminder: [String: String]?
    var otherNightReminder: [String: String]?

    init(id: String, name: [String : String], teamRaw: String? = nil, ability: [String : String]? = nil, reminders: [String : [String]]? = nil, firstNightReminder: [String : String]? = nil, otherNightReminder: [String : String]? = nil) {
        self.id = id
        self.name = name
        self.teamRaw = teamRaw
        self.ability = ability
        self.reminders = reminders
        self.firstNightReminder = firstNightReminder
        self.otherNightReminder = otherNightReminder
    }
}

extension Character {
    /// Regresa el string preferido según el idioma de sistema,
    /// o fallback a inglés, o lo primero disponible
    static func localizedString(_ dict: [String: String]?, defaultLang: String = "en") -> String {
        guard let dict = dict else { return "" }
        // El idioma preferido del sistema
        let preferred = Locale.preferredLanguages
            .compactMap { $0.components(separatedBy: "-").first } // "es-MX" -> "es"
        for langCode in preferred {
            if let txt = dict[langCode], !txt.isEmpty { return txt }
        }
        // Fallback a inglés
        if let en = dict[defaultLang], !en.isEmpty { return en }
        // Fallback a cualquier otro
        if let any = dict.values.first { return any }
        return ""
    }

    func nameLocalized() -> String {
        Character.localizedString(self.name)
    }
    func abilityLocalized() -> String {
        Character.localizedString(self.ability)
    }
    func firstNightReminderLocalized() -> String {
        Character.localizedString(self.firstNightReminder)
    }
    func otherNightReminderLocalized() -> String {
        Character.localizedString(self.otherNightReminder)
    }
    func remindersLocalized() -> [String] {
        let lang = Locale.preferredLanguages.first?
            .components(separatedBy: "-").first ?? "en"
        if let all = reminders {
            // Si existe para ese idioma, regresa ese array, si no el de "en", si no cualquier
            if let arr = all[lang], !arr.isEmpty { return arr }
            if let enarr = all["en"], !enarr.isEmpty { return enarr }
            if let any = all.values.first, !any.isEmpty { return any }
        }
        return []
    }
}
