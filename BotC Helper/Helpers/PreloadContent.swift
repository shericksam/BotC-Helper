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
        guard !didPreload else { return }

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
            let rolesEntities = roles.map { r in
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
                    special: r.special?.map { RoleDefinition.SpecialProperty(name: $0.name, type: $0.type, time: $0.time, value: $0.value) }
                )
            }
            let editionEntity = EditionData(meta: metaEntity, characters: rolesEntities)
            modelContext.insert(editionEntity)
        }

        // 2. Pre-cargar todos los roles posibles (si tu modelo lo requiere aparte)
        for role in loadPredefinedRoles() {
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
                special: role.special?.map { RoleDefinition.SpecialProperty(name: $0.name, type: $0.type, time: $0.time, value: $0.value) }
            )
            modelContext.insert(roleEntity)
        }

        UserDefaults.standard.set(true, forKey: didPreloadKey)
    }
}
