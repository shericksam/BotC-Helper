//
//  PreloadContent.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 07/12/25.
//

import Foundation
import SwiftData

struct PreloadContent {
    let didPreloadKey = "didPreloadInitialData"
    // Llama esto solo la primera vez (usa la bandera UserDefaults)
    @MainActor
    func preloadDefaultEditionsAndRolesIfNeeded(modelContext: ModelContext) async {
        let didPreload = UserDefaults.standard.bool(forKey: didPreloadKey)
//        guard !didPreload else { return }

        // 1. Pre-cargar ediciones base del bundle
        for editionSummary in EditionSummaryModel.defaultEditions {
            let baseFileName = editionSummary.fileName.replacingOccurrences(of: ".json", with: "")
            guard let url = Bundle.main.url(forResource: baseFileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let jsonArr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let meta = jsonArr.first,
                  let metaData = try? JSONSerialization.data(withJSONObject: meta),
                  let metaStruct = try? JSONDecoder().decode(EditionMetaModel.self, from: metaData)
            else { continue }

            // Carga los roles
            let characterArr = jsonArr.dropFirst()
            let roles: [RoleDefinitionModel] = characterArr.compactMap { dict in
                guard let data = try? JSONSerialization.data(withJSONObject: dict),
                      let character = try? JSONDecoder().decode(RoleDefinitionModel.self, from: data)
                else { return nil }
                return character
            }

            // Instancia entidad SwiftData:
            let metaEntity = EditionMeta(id: metaStruct.id, name: metaStruct.name, author: metaStruct.author, firstNight: metaStruct.firstNight, otherNight: metaStruct.otherNight)
            let roleEntities: [RoleDefinition] = roles.map { r in
                RoleDefinition(
                    id: r.id,
                    name: r.name,
                    team: r.team,
                    ability: r.ability,
                    setup: r.setup,
                    iconName: r.iconName,
                    reminders: r.reminders,
                    remindersGlobal: r.remindersGlobal,
                    firstNightReminder: r.firstNightReminder,
                    otherNightReminder: r.otherNightReminder,
                    special: []
                )
            }
            for (index, role) in roles.enumerated() {
                guard let specials = role.special else { continue }
                let roleEntity = roleEntities[index]
                let specialEntities = specials.map { s in
                    let special = SpecialProperty(
                        name: s.name,
                        type: s.type,
                        time: s.time,
                        value: s.value
                    )
                    special.parentRole = roleEntity
                    return special
                }
                // 3. Asigna la relación al roleEntity
                roleEntity.special = specialEntities
            }
            let editionEntity = EditionData(meta: metaEntity, characters: roleEntities)
            modelContext.insert(editionEntity)
        }

        // 2. Pre-cargar todos los roles posibles (si tu modelo lo requiere aparte)
        for role in loadPredefinedRoles() {
            // 1. Crea roleEntity sin specials
            let roleEntity = RoleDefinition(
                id: role.id,
                name: role.name,
                team: role.team,
                ability: role.ability,
                setup: role.setup,
                iconName: role.iconName,
                reminders: role.reminders,
                remindersGlobal: role.remindersGlobal,
                firstNightReminder: role.firstNightReminder,
                otherNightReminder: role.otherNightReminder,
                special: [] // temporalmente vacío
            )
            // 2. Crea los special con la relación inversa apuntando al roleEntity
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
            modelContext.insert(roleEntity)
        }

        UserDefaults.standard.set(true, forKey: didPreloadKey)
        try? modelContext.save()
    }
}
