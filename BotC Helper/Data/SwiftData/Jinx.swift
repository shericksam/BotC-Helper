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

    init(id: String, roles: [String], description: String, image: [String]?) {
        self.id = id
        self.roles = roles
        self.desc = description
        self.image = image
    }
}

extension Jinx {
    static func upsert(
        id: String,
        roles: [String],
        description: String,
        image: [String]?,
        modelContext: ModelContext
    ) -> Jinx {
        let fetch = FetchDescriptor<Jinx>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        if let existing = fetched.first {
            // Actualizar si quieres, por ejemplo si la desc cambió
            existing.roles = roles
            existing.desc = description
            existing.image = image
            modelContext.insert(existing)
            return existing
        } else {
            let new = Jinx(id: id, roles: roles, description: description, image: image)
            modelContext.insert(new)
            return new
        }
    }
}
