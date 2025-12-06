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
        case .townsfolk: return "Aldeano"
        case .outsider: return "Forastero"
        case .minion: return "Esbirro"
        case .demon: return "Demonio"
        case .traveller: return "Viajero"
        case .fabled: return "Fábula"
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
