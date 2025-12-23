//
//  EditionSummary.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import SwiftData

@Model
final class EditionSummary: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var fileName: String
    var imageName: String?
    var isFromBundle: Bool

    init(id: String, name: String, fileName: String, imageName: String?, isFromBundle: Bool = true) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.imageName = imageName
        self.isFromBundle = isFromBundle
    }
}
