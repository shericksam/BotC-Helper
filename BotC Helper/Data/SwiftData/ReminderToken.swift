//
//  ReminderToken.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ReminderToken {
    @Attribute(.unique) var id: UUID
    var text: String
    var posX: Double
    var posY: Double
    var colorName: String

    init(text: String, posX: Double = 0.5, posY: Double = 0.5, colorName: String = "blue") {
        self.id = UUID()
        self.text = text
        self.posX = posX
        self.posY = posY
        self.colorName = colorName
    }

    var uiColor: Color {
        switch colorName {
        case "red":    return .red
        case "green":  return .green
        case "purple": return .purple
        case "orange": return .orange
        case "teal":   return .teal
        case "gray":   return .gray
        default:       return .blue
        }
    }
}
