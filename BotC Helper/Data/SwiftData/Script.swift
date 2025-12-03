//
//  Script.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
import SwiftData

@Model
final class Script {
    @Attribute(.unique) var id: String
    var name: String
    @Relationship(deleteRule: .cascade) var characters: [Character] = []

    init(id: String, name: String, characters: [Character]) {
        self.id = id
        self.name = name
        self.characters = characters
    }
}
