//
//  Player.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var seatNumber: Int
    var name: String
    var claimRoleId: String?
    var claimManual: String
    var isMe: Bool
    // No Dictionary; modela como lista de notas personales asociadas a día:
    @Relationship(deleteRule: .cascade) var personalNotes: [PersonalNote] = []

    init(
        seatNumber: Int,
        name: String,
        claimRoleId: String? = nil,
        claimManual: String = "",
        isMe: Bool = false,
        personalNotes: [PersonalNote] = []
    ) {
        id = UUID()
        self.seatNumber = seatNumber
        self.name = name
        self.claimRoleId = claimRoleId
        self.claimManual = claimManual
        self.isMe = isMe
        self.personalNotes = personalNotes
    }
}

@Model
final class PersonalNote {
    var dayIndex: Int
    var text: String

    init(dayIndex: Int, text: String) {
        self.dayIndex = dayIndex
        self.text = text
    }
}

@Model
final class GameConfig {
    var numPlayers: Int
    var numTownsfolk: Int
    var numOutsider: Int
    var numMinions: Int
    var numDemon: Int

    init(numPlayers: Int, numTownsfolk: Int, numOutsider: Int, numMinions: Int, numDemon: Int) {
        self.numPlayers = numPlayers
        self.numTownsfolk = numTownsfolk
        self.numOutsider = numOutsider
        self.numMinions = numMinions
        self.numDemon = numDemon
    }
}
