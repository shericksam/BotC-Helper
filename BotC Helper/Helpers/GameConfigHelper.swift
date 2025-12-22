//
//  GameConfigHelper.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

func getConfigForPlayerCount(_ count: Int) -> GameConfigModel {
    switch count {
    case 5:
        return GameConfigModel(numPlayers: 5, numTownsfolk: 3, numOutsider: 0, numMinions: 1, numDemon: 1)
    case 6:
        return GameConfigModel(numPlayers: 6, numTownsfolk: 3, numOutsider: 1, numMinions: 1, numDemon: 1)
    case 7:
        return GameConfigModel(numPlayers: 7, numTownsfolk: 5, numOutsider: 0, numMinions: 1, numDemon: 1)
    case 8:
        return GameConfigModel(numPlayers: 8, numTownsfolk: 5, numOutsider: 1, numMinions: 1, numDemon: 1)
    case 9:
        return GameConfigModel(numPlayers: 9, numTownsfolk: 5, numOutsider: 2, numMinions: 1, numDemon: 1)
    case 10:
        return GameConfigModel(numPlayers: 10, numTownsfolk: 7, numOutsider: 0, numMinions: 2, numDemon: 1)
    case 11:
        return GameConfigModel(numPlayers: 11, numTownsfolk: 7, numOutsider: 1, numMinions: 2, numDemon: 1)
    case 12:
        return GameConfigModel(numPlayers: 12, numTownsfolk: 7, numOutsider: 2, numMinions: 2, numDemon: 1)
    case 13:
        return GameConfigModel(numPlayers: 13, numTownsfolk: 9, numOutsider: 0, numMinions: 3, numDemon: 1)
    case 14:
        return GameConfigModel(numPlayers: 14, numTownsfolk: 9, numOutsider: 1, numMinions: 3, numDemon: 1)
    case 15:
        return GameConfigModel(numPlayers: 15, numTownsfolk: 9, numOutsider: 2, numMinions: 3, numDemon: 1)
    default:
        return GameConfigModel(numPlayers: count, numTownsfolk: 9, numOutsider: 2, numMinions: 3, numDemon: 1)
    }
}
