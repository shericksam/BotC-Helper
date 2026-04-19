//
//  Friend.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import Foundation
import SwiftData

@Model
final class Friend {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
