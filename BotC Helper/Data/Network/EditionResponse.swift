//
//  EditionResponse.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation

struct RawEdition: Decodable {
    var id: String
    var name: String
    var author: String?
    var firstNight: [String]
    var otherNight: [String]
    // Puedes agregar otras propiedades si quieres
}

struct RawCharacter: Decodable {
    var id: String
    var name: String
    var team: String?
    var ability: String?
    var setup: Bool?
    var image: [String]?
    var reminders: [String]?
    var firstNightReminder: String?
    var otherNightReminder: String?
}
