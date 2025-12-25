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
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify) var meta: EditionMeta
    @Relationship(deleteRule: .nullify) var characters: [RoleDefinition] = []
    @Relationship(deleteRule: .nullify) var jinxes: [Jinx] = []

    init(meta: EditionMeta, characters: [RoleDefinition], jinxes: [Jinx] = []) {
        self.id = meta.id
        self.meta = meta
        self.characters = characters
        self.jinxes = jinxes
    }
}

extension EditionData {
    static func upsert(id: String,
                       meta: EditionMeta,
                       characters: [RoleDefinition],
                       jinxes: [Jinx],
                       modelContext: ModelContext) -> EditionData {
        let fetch = FetchDescriptor<EditionData>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []

        if let existing = fetched.first {
            if existing.meta != meta { existing.meta = meta }
            if existing.characters != characters { existing.characters = characters }
            if existing.jinxes != jinxes { existing.jinxes = jinxes }
            return existing
        } else {
            let new = EditionData(meta: meta, characters: characters, jinxes: jinxes)
            modelContext.insert(new)
            return new
        }
    }
}
