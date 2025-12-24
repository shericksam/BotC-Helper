//
//  Team.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation
import SwiftUI

enum Team: String, Codable, CaseIterable, Hashable {
    case townsfolk = "townsfolk"
    case outsider = "outsider"
    case minion = "minion"
    case demon = "demon"
    case traveller = "traveller"
    case fabled = "fabled"

    var displayName: String {
        switch self {
        case .townsfolk: return MSG("team_townsfolk")
        case .outsider: return MSG("team_outsider")
        case .minion: return MSG("team_minion")
        case .demon: return MSG("team_demon")
        case .traveller: return MSG("team_traveller")
        case .fabled: return MSG("team_fabled")
        }
    }

    var color: Color {
        switch self {
        case .townsfolk: return .blue
        case .outsider: return .teal
        case .minion: return .purple
        case .demon: return .red
        case .traveller: return .orange
        case .fabled: return .gray
        }
    }
}
