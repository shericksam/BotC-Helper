//
//  QuickImport.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

struct QuickImport {
    static func createEditionData(from structEdition: EditionDataModel) -> EditionData {
        let meta = EditionMeta(
            id: structEdition.meta.id,
            name: structEdition.meta.name,
            author: structEdition.meta.author,
            firstNight: structEdition.meta.firstNight,
            otherNight: structEdition.meta.otherNight
        )
        let roles = structEdition.characters.map { role in
            RoleDefinition(
                id: role.id,
                name: role.name,
                team: role.team,
                ability: role.ability,
                setup: role.setup,
                iconName: role.getImageName(),
                reminders: role.reminders,
                remindersGlobal: role.remindersGlobal,
                firstNightReminder: role.firstNightReminder,
                otherNightReminder: role.otherNightReminder,
                special: role.special?.map { sp in
                    RoleDefinition.SpecialProperty(name: sp.name, type: sp.type, time: sp.time, value: sp.value)
                }
            )
        }
        return EditionData(meta: meta, characters: roles)
    }
}
