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
