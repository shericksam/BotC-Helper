//
//  BoardStateModel.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation

struct BoardStateModel: Codable, Equatable {
    var id: UUID = UUID()
    var suggestedName: String
    var players: [PlayerModel]
    // [Día 0, Día 1, Día 2, ...] (status de cada jugador por día)
    var days: [[PlayerStatusPerDayModel]]
    var currentDay: Int
    var config: GameConfigModel
    var edition: EditionDataModel? = nil

    struct Mock {
        static var example: BoardStateModel {
            let playerCount = 20
            let players = (1...playerCount).map {
                PlayerModel(seatNumber: $0, name: "", claimManual: "")
            }
            // Día 0: todos vivos, nadie votó
            let day0 = players.map { p in PlayerStatusPerDayModel(seatNumber: p.seatNumber) }
            let config = getConfigForPlayerCount(playerCount)
            return BoardStateModel(suggestedName: suggestedFileName(playersCount: playerCount), players: players, days: [day0], currentDay: 0, config: .init(numPlayers: playerCount, numTownsfolk: 8, numOutsider: 0, numMinions: 0, numDemon: 0), edition: EditionDataModel.Mock.editionData)
        }
    }

}

struct GameConfigModel: Codable, Equatable {
    var numPlayers: Int
    var numTownsfolk: Int
    var numOutsider: Int
    var numMinions: Int
    var numDemon: Int
}
