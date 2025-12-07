//
//  ChatMessage.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    let isUser: Bool
    let text: String
}
