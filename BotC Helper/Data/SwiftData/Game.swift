////
////  Game.swift
////  BotC Helper
////
////  Created by Erick Samuel Guerrero Arreola on 03/12/25.
////
//
//import Foundation
//import SwiftData
//
//@Model
//final class Game {
//    @Attribute(.unique) var id: String
//    var date: Date
//    var config: GameConfig
//    @Relationship(deleteRule: .cascade) var players: [Player] = []
//    @Relationship(deleteRule: .cascade) var days: [GameDay] = []
//
//    init(id: String = UUID().uuidString, date: Date = .now, config: GameConfig) {
//        self.id = id
//        self.date = date
//        self.config = config
//    }
//}
//
//@Model
//final class GameConfig {
//    var numPlayers: Int
//    var numTownsfolk: Int
//    var numOutsider: Int
//    var numMinions: Int
//    var numDemon: Int
//    // ...más adelante: edición, customRoles …
//
//    init(numPlayers: Int, numTownsfolk: Int, numOutsider: Int, numMinions: Int, numDemon: Int) {
//        self.numPlayers = numPlayers
//        self.numTownsfolk = numTownsfolk
//        self.numOutsider = numOutsider
//        self.numMinions = numMinions
//        self.numDemon = numDemon
//    }
//}
//
//@Model
//final class Player {
//    @Attribute(.unique) var id: String
//    var seatNumber: Int
//    var name: String
//    var claim: String
//    var isYou: Bool
//
//    init(seatNumber: Int, name: String = "", claim: String = "", isYou: Bool = false) {
//        self.id = UUID().uuidString
//        self.seatNumber = seatNumber
//        self.name = name
//        self.claim = claim
//        self.isYou = isYou
//    }
//}
//
//@Model
//final class GameDay {
//    var dayNumber: Int
//    @Relationship(deleteRule: .cascade) var playerStatuses: [PlayerStatus] = []
//
//    init(dayNumber: Int) {
//        self.dayNumber = dayNumber
//    }
//}
//
//@Model
//final class PlayerStatus {
//    @Attribute(.unique) var id: String
//    var seatNumber: Int
//    var voted: Bool
//    var nominated: Bool
//    var dead: Bool
//    var notes: String   // General, visible por todos
//
//    // Para el dueño:
//    var personalNotes: String   // Notas personales si eres tú
//
//    init(seatNumber: Int, voted: Bool = false, nominated: Bool = false, dead: Bool = false, notes: String = "", personalNotes: String = "") {
//        self.id = UUID().uuidString
//        self.seatNumber = seatNumber
//        self.voted = voted
//        self.nominated = nominated
//        self.dead = dead
//        self.notes = notes
//        self.personalNotes = personalNotes
//    }
//}
