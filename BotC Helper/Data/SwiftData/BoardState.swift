//
//  BoardState.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class BoardState {
    @Attribute(.unique) var id: UUID
    var suggestedName: String
    @Relationship(deleteRule: .cascade) var players: [Player] = []
    @Relationship(deleteRule: .cascade) var days: [GameDay] = []
    var currentDay: Int
    var config: GameConfigModel
    @Relationship var edition: EditionData?

    init(
        suggestedName: String,
        players: [Player],
        days: [GameDay],
        currentDay: Int,
        config: GameConfigModel,
        edition: EditionData? = nil
    ) {
        id = UUID()
        self.suggestedName = suggestedName
        self.players = players
        self.days = days
        self.currentDay = currentDay
        self.config = config
        self.edition = edition
    }
}

@Model
final class GameDay {
    @Attribute(.unique) var id: UUID
    var index: Int
    @Relationship(deleteRule: .cascade) var playerStatuses: [PlayerStatus] = []

    init(index: Int, playerStatuses: [PlayerStatus]) {
        id = UUID()
        self.index = index
        self.playerStatuses = playerStatuses
    }
}

@Model
final class PlayerStatus {
    @Attribute(.unique) var id: UUID
    var seatNumber: Int
    var voted: Bool
    var nominated: Bool
    var dead: Bool
    var claim: String
    var notes: String

    init(seatNumber: Int, voted: Bool = false, nominated: Bool = false, dead: Bool = false, claim: String = "", notes: String = "") {
        self.id = UUID()
        self.seatNumber = seatNumber
        self.voted = voted
        self.nominated = nominated
        self.dead = dead
        self.claim = claim
        self.notes = notes
    }
}
