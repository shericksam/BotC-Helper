//
//  JinxModel.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation

struct JinxModel: Codable {
    var id: String
    var roles: [String]
    var desc: String
    var image: [String]?
    var text: String?

    enum CodingKeys: String, CodingKey {
        case id, roles, image
        case text
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.roles = try container.decode([String].self, forKey: .roles)
        self.image = try container.decodeIfPresent([String].self, forKey: .image)

        let textDict = try container.decode([String: String].self, forKey: .text)
        let preferred = Locale.preferredLanguages.compactMap { $0.components(separatedBy: "-").first }
        self.desc = preferred.compactMap { textDict[$0] }.first
            ?? textDict["en"]
            ?? textDict.values.first
            ?? ""
    }
}
