//
//  BoardState.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation

struct BoardState: Codable, Equatable {
    var id: UUID = UUID()
    var players: [Player]
    // [Día 0, Día 1, Día 2, ...] (status de cada jugador por día)
    var days: [[PlayerStatusPerDay]]
    var currentDay: Int
    var config: GameConfig

    struct Mock {
        static var example: BoardState {
            let playerCount = 20
            let players = (1...playerCount).map {
                Player(seatNumber: $0, name: "", claim: "")
            }
            // Día 0: todos vivos, nadie votó
            let day0 = players.map { p in PlayerStatusPerDay(seatNumber: p.seatNumber) }
            let config = getConfigForPlayerCount(playerCount)
            return BoardState(players: players, days: [day0], currentDay: 0, config: config)
        }
    }
}

struct GameConfig: Codable, Equatable {
    var numPlayers: Int
    var numTownsfolk: Int
    var numOutsider: Int
    var numMinions: Int
    var numDemon: Int
}
