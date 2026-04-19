//
//  PlayerStatus.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class PlayerStatus {
    @Attribute(.unique) var id: UUID
    var dayIndex: Int
    var seatNumber: Int
    var voted: Bool
    var nominated: Bool
    var dead: Bool
    var deathType: String?
    var claim: String
    var notes: String

    init(dayIndex: Int, seatNumber: Int = 0, voted: Bool = false, nominated: Bool = false, dead: Bool = false, deathType: String? = nil, claim: String = "", notes: String = "") {
        self.id = UUID()
        self.dayIndex = dayIndex
        self.seatNumber = seatNumber
        self.voted = voted
        self.nominated = nominated
        self.dead = dead
        self.deathType = deathType
        self.claim = claim
        self.notes = notes
    }
}
