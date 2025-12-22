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
    var config: GameConfig
    @Relationship var edition: EditionData?

    init(
        suggestedName: String,
        players: [Player],
        days: [GameDay],
        currentDay: Int,
        config: GameConfig,
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
