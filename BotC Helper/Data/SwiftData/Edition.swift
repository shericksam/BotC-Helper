//
//  Edition.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
import SwiftData

@Model
final class Edition {
    @Attribute(.unique) var id: String
    var name: String
    var synopsis: String?
    var howToPlay: String?
    var nightOrderFirst: [String]      // ids (ej: ["secta_chef",...])
    var nightOrderOther: [String]
    @Relationship(deleteRule: .cascade) var scripts: [Script] = []

    init(id: String, name: String, synopsis: String? = nil, howToPlay: String? = nil, nightOrderFirst: [String], nightOrderOther: [String], scripts: [Script] = []) {
        self.id = id
        self.name = name
        self.synopsis = synopsis
        self.howToPlay = howToPlay
        self.nightOrderFirst = nightOrderFirst
        self.nightOrderOther = nightOrderOther
        self.scripts = scripts
    }



//    struct Mock {
//        static func all() -> [Edition] {
//            [
////                Edition(name: "Trouble Brewing", description: "Juego base original."),
////                Edition(name: "Bad Moon Rising", description: "Edición avanzada con nuevos roles."),
////                Edition(name: "Custom", description: "Tu edición personalizada.")
//            ]
//        }
//    }
}
