//
//  GameDay.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

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
