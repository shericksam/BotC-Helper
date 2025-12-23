//
//  PreloadContent.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

struct PreloadContent {
    let didPreloadKey = "didPreloadInitialData"

    @MainActor
    func preloadDefaultEditionsAndRolesIfNeeded(modelContext: ModelContext) async {
        let didPreload = UserDefaults.standard.bool(forKey: didPreloadKey)
        print("didPreload--->\(didPreload)")
//        guard !didPreload else { return }
        loadAndSaveRoles(modelContext: modelContext)
        // 1. Pre-cargar ediciones base del bundle
        saveEditions(modelContext: modelContext)
//        UserDefaults.standard.set(true, forKey: didPreloadKey)
        try? modelContext.save()
    }

    func loadAndSaveRoles(modelContext: ModelContext) {
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

    }

    func saveEditions(modelContext: ModelContext) {
        for editionSummary in EditionSummaryModel.defaultEditions {
            let baseFileName = editionSummary.fileName.replacingOccurrences(of: ".json", with: "")
            guard let url = Bundle.main.url(forResource: baseFileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let jsonArr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let meta = jsonArr.first,
                  let metaData = try? JSONSerialization.data(withJSONObject: meta),
                  let metaStruct = try? JSONDecoder().decode(EditionMetaModel.self, from: metaData)
            else { continue }

            let characterArr = jsonArr.dropFirst()
            let roles: [RoleDefinitionModel] = characterArr.compactMap { dict in
                guard let data = try? JSONSerialization.data(withJSONObject: dict),
                      let character = try? JSONDecoder().decode(RoleDefinitionModel.self, from: data)
                else { return nil }
                return character
            }

            let metaEntity = EditionMeta(id: metaStruct.id, name: metaStruct.name, author: metaStruct.author, firstNight: metaStruct.firstNight, otherNight: metaStruct.otherNight)
            var roleEntities: [RoleDefinition] = []

            for r in roles {
                // 1. Busca si ya existe un role con ese id:
                let fetch = FetchDescriptor<RoleDefinition>(predicate: #Predicate { $0.id == r.id })
                let existingRoles = (try? modelContext.fetch(fetch)) ?? []
                let roleEntity: RoleDefinition

                if let existing = existingRoles.first {
                    // 2. Si existe y tiene info incompleta, actualízalo
                    if existing.name.isEmpty { existing.name = r.name }
                    if existing.ability == nil || existing.ability?.isEmpty == true { existing.ability = r.ability }
                    if existing.team == nil { existing.team = r.team }
                    // ...otros campos como desees...
                    roleEntity = existing
                } else {
                    // 3. Si no existe, lo creas normalmente
                    roleEntity = RoleDefinition(
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
                    modelContext.insert(roleEntity)
                }
                // specials como antes
                if let specials = r.special {
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
                    roleEntity.special = specialEntities
                }
                roleEntities.append(roleEntity)
            }

            let editionEntity = EditionData(meta: metaEntity, characters: roleEntities)
            modelContext.insert(editionEntity)
        }
    }
}
