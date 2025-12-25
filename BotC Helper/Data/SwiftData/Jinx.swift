//
//  Jinx.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class Jinx {
    @Attribute(.unique) var id: String
    var roles: [String]
    var desc: String
    var image: [String]?
    @Relationship(inverse: \EditionData.jinxes) var editions: [EditionData]

    init(id: String, roles: [String], description: String, image: [String]?, editions: [EditionData] = []) {
        self.id = id
        self.roles = roles
        self.desc = description
        self.image = image
        self.editions = editions
    }
}

extension Jinx {
    static func upsert(id: String,
                       roles: [String],
                       description: String,
                       image: [String]?,
                       edition: EditionData?,
                       modelContext: ModelContext) -> Jinx {
        let fetch = FetchDescriptor<Jinx>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        if let existing = fetched.first {
            existing.roles = roles
            existing.desc = description
            existing.image = image
            return existing
        } else {
            let new = Jinx(id: id, roles: roles, description: description, image: image)
            if let edition {
                new.editions.append(edition)
            }
            modelContext.insert(new)
            return new
        }
    }
}
