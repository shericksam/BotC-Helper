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
    @Relationship(deleteRule: .nullify) var players: [Player] = []
    var currentDay: Int
    var config: GameConfig
    @Relationship(deleteRule: .nullify) var edition: EditionData?
    @Relationship(deleteRule: .cascade) var reminders: [ReminderToken] = []
    var activeFabledIds: [String] = []
    var createdAt: Date = Date()
    var winner: String? = nil  // "good", "evil", or nil
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
