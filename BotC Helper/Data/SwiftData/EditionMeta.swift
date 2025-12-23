//
//  Edition.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import Foundation
import SwiftData

@Model
final class EditionMeta {
    @Attribute(.unique) var id: String
    var name: String
    var author: String?
    var imageName: String?
    var firstNight: [String]
    var otherNight: [String]

    init(id: String, name: String, author: String? = nil, imageName: String? = nil, firstNight: [String], otherNight: [String]) {
        self.id = id
        self.name = name
        self.author = author
        self.imageName = imageName
        self.firstNight = firstNight
        self.otherNight = otherNight
    }
}

extension EditionMeta {
    static func upsert(id: String,
                       name: String,
                       author: String? = nil,
                       imageName: String? = nil,
                       firstNight: [String],
                       otherNight: [String],
                       modelContext: ModelContext) -> EditionMeta {
        let fetch = FetchDescriptor<EditionMeta>(predicate: #Predicate { $0.id == id })
        let fetched = (try? modelContext.fetch(fetch)) ?? []
        if let existing = fetched.first {
            if existing.name != name { existing.name = name }
            if existing.author != author { existing.author = author }
            if existing.imageName != imageName { existing.imageName = imageName }
            if existing.firstNight != firstNight { existing.firstNight = firstNight }
            if existing.otherNight != otherNight { existing.otherNight = otherNight }
            return existing
        } else {
            let new = EditionMeta(id: id, name: name, imageName: imageName, firstNight: firstNight, otherNight: otherNight)
            modelContext.insert(new)
            return new
        }
    }
}
