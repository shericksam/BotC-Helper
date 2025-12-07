//
//  PlayerStatusPerDay.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
// Representa el estado de un jugador en un día específico
struct PlayerStatusPerDayModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var seatNumber: Int
    var voted: Bool = false
    var nominated: Bool = false
    var dead: Bool = false
    var claim: String = ""
    var notes: String = ""
}

// El jugador (sus datos constantes)
struct PlayerModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var seatNumber: Int
    var initials: String { initialsForName(name) }
    var name: String
    var claimRoleId: String?
    var claimManual: String
    var isMe: Bool = false
    var personalNotes: [Int: String] = [:] // <- notas personales por día

    /// Calcula iniciales robustamente
    private func initialsForName(_ name: String) -> String {
        let comps = name.split(separator: " ")
        if comps.count > 1 {
            return String(comps[0].prefix(1) + comps[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}
