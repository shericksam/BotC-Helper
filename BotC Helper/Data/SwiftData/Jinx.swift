//
//  Jinx.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class Jinx {
    var id: String
    var roles: [String]
    var desc: String
    var image: [String]?

    init(id: String, roles: [String], description: String, image: [String]?) {
        self.id = id
        self.roles = roles
        self.desc = description
        self.image = image
    }
}
