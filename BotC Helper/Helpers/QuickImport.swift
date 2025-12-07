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
            let roleEntity = RoleDefinition(
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
                special: []
            )
            if let specials = role.special {
                let spEntities = specials.map { spModel in
                    let sp = SpecialProperty(
                        name: spModel.name,
                        type: spModel.type,
                        time: spModel.time,
                        value: spModel.value
                    )
                    sp.parentRole = roleEntity       // RELACIÓN INVERSA CLAVE
                    return sp
                }
                roleEntity.special = spEntities
            }
            return roleEntity
        }
        return EditionData(meta: meta, characters: roles)
    }
}
