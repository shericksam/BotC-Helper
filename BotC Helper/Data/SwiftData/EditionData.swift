//
//  EditionData.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class EditionData {
    @Relationship(deleteRule: .cascade) var meta: EditionMeta?
    @Relationship(deleteRule: .cascade) var characters: [RoleDefinition] = []
    @Relationship(deleteRule: .nullify) var jinxes: [Jinx] = []

    var id: String { meta?.id ?? UUID().uuidString }

    init(meta: EditionMeta, characters: [RoleDefinition], jinxes: [Jinx] = []) {
        self.meta = meta
        self.characters = characters
        self.jinxes = jinxes
    }
}
