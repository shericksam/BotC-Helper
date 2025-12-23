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

    enum CodingKeys: String, CodingKey {
        case id
        case roles
        case desc = "description"
        case image
    }
    
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.roles = try container.decode([String].self, forKey: .roles)
        self.desc = try container.decode(String.self, forKey: .desc)
        self.image = try container.decodeIfPresent([String].self, forKey: .image)
    }
}

