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
