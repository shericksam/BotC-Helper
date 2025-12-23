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
    var currentDay: Int
    var config: GameConfig
    @Relationship var edition: EditionData?
    var totalDays: Int { players.first?.statuses.count ?? 0 }

    init(id: UUID = UUID(),
         suggestedName: String,
         players: [Player],
         currentDay: Int,
         config: GameConfig,
         edition: EditionData? = nil) {
        self.id = id
        self.suggestedName = suggestedName
        self.players = players
        self.currentDay = currentDay
        self.config = config
        self.edition = edition
    }
}
