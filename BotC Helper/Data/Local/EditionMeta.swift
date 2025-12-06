//
//  EditionMeta.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation
struct EditionMeta: Decodable, Encodable {
    let id: String
    let name: String
    let author: String?
    let firstNight: [String]
    let otherNight: [String]
}

struct RoleDefinition: Decodable, Identifiable, Encodable, Hashable, Equatable {
    let id: String
    let name: String
    let team: Team?
    let ability: String?
    let setup: Bool?
    var iconName: String {
        getImageName()
    }
    let reminders: [String]?
    let remindersGlobal: [String]?
    let firstNightReminder: String?
    let otherNightReminder: String?
    let special: [SpecialProperty]?

    struct SpecialProperty: Decodable, Encodable, Hashable {
        let name: String
        let type: String
        let time: String?
        let value: String?
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case team
        case ability
        case setup
        case reminders
        case remindersGlobal
        case firstNightReminder
        case otherNightReminder
        case special
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        if let teamStr = try? container.decode(String.self, forKey: .team) {
            team = Team(rawValue: teamStr)
        } else {
            team = nil
        }
        self.ability = try container.decodeIfPresent(String.self, forKey: .ability)
        self.setup = try container.decodeIfPresent(Bool.self, forKey: .setup)
        self.reminders = try container.decodeIfPresent([String].self, forKey: .reminders)
        self.remindersGlobal = try container.decodeIfPresent([String].self, forKey: .remindersGlobal)
        self.firstNightReminder = try container.decodeIfPresent(String.self, forKey: .firstNightReminder)
        self.otherNightReminder = try container.decodeIfPresent(String.self, forKey: .otherNightReminder)
        self.special = try container.decodeIfPresent([RoleDefinition.SpecialProperty].self, forKey: .special)
    }

    static func == (lhs: RoleDefinition, rhs: RoleDefinition) -> Bool {
        lhs.id == rhs.id
    }
    func getImageName() -> String {
        id.replacing("secta_", with: "")
    }
}

struct EditionData: Decodable, Encodable, Equatable {
    var id: String { meta.id }
    let meta: EditionMeta
    let characters: [RoleDefinition]

    static func == (lhs: EditionData, rhs: EditionData) -> Bool {
        lhs.id == rhs.id
    }
}

extension EditionData {
    struct Mock {
        static var editionData: EditionData? {
            let edition = EditionSummary(id: "tb", name: "Trouble Brewing", fileName: "trouble_brewing.json", imageName: "logo_trouble_brewing")
            return mockLoadEditionDetails(edition: edition)
        }
    }
}
