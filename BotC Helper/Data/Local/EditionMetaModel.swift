//
//  EditionMetaModel.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

struct EditionMetaModel: Decodable, Encodable {
    let id: String
    let name: String
    let author: String?
    let firstNight: [String]
    let otherNight: [String]
}

struct RoleDefinitionModel: Codable {
    let id: String
    let name: [String: String]
    let team: Team?
    let ability: [String: String]?
    let setup: Bool?
    let reminders: [String: [String]]?
    let remindersGlobal: [String: [String]]?
    let firstNightReminder: [String: String]?
    let otherNightReminder: [String: String]?
    let special: [SpecialProperty]?

    struct SpecialProperty: Codable, Hashable {
        let name: String
        let type: String
        let time: String?
        let value: String?
    }

    enum CodingKeys: CodingKey {
        case id, name, team, ability, setup, reminders, remindersGlobal, firstNightReminder, otherNightReminder, special
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)

        // Support both string and dictionary for name/ability for backward compatibility
        self.name = try container.decodeIfPresent([String: String].self, forKey: .name)
            ?? ["es": (try? container.decode(String.self, forKey: .name)) ?? ""]

        if let teamStr = try? container.decode(String.self, forKey: .team) {
            team = Team(rawValue: teamStr)
        } else {
            team = nil
        }

        self.ability = try container.decodeIfPresent([String: String].self, forKey: .ability)
            ?? (try? container.decode(String.self, forKey: .ability)).map { ["es": $0] }

        self.setup = try container.decodeIfPresent(Bool.self, forKey: .setup)

        self.reminders = try container.decodeIfPresent([String: [String]].self, forKey: .reminders)
            ?? (try? container.decode([String].self, forKey: .reminders)).map { ["es": $0] }

        self.remindersGlobal = try container.decodeIfPresent([String: [String]].self, forKey: .remindersGlobal)
            ?? (try? container.decode([String].self, forKey: .remindersGlobal)).map { ["es": $0] }

        self.firstNightReminder = try container.decodeIfPresent([String: String].self, forKey: .firstNightReminder)
            ?? (try? container.decode(String.self, forKey: .firstNightReminder)).map { ["es": $0] }

        self.otherNightReminder = try container.decodeIfPresent([String: String].self, forKey: .otherNightReminder)
            ?? (try? container.decode(String.self, forKey: .otherNightReminder)).map { ["es": $0] }

        self.special = try container.decodeIfPresent([SpecialProperty].self, forKey: .special)
    }

}

struct EditionDataModel: Decodable, Encodable, Equatable {
    var id: String { meta.id }
    let meta: EditionMetaModel
    let characters: [RoleDefinitionModel]

    static func == (lhs: EditionDataModel, rhs: EditionDataModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension EditionDataModel {
    struct Mock {
        static var editionData: EditionDataModel? {
            let edition = EditionSummaryModel(id: "tb", name: "Trouble Brewing", fileName: "trouble_brewing.json", imageName: "logo_trouble_brewing")
            return mockLoadEditionDetails(edition: edition)
        }
    }
}
