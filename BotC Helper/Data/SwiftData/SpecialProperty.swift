//
//  SpecialProperty.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class SpecialProperty {
    var name: String
    var type: String
    var time: String?
    var value: String?
    @Relationship var parentRole: RoleDefinition?

    init(name: String, type: String, time: String? = nil, value: String? = nil, parentRole: RoleDefinition? = nil) {
        self.name = name
        self.type = type
        self.time = time
        self.value = value
        self.parentRole = parentRole
    }
}
