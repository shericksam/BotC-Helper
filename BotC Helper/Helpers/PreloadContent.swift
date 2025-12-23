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
        guard !didPreload else { return }
        loadAndSaveRoles(modelContext: modelContext)

        loadAndSaveJinxes(modelContext: modelContext)

        // 1. Pre-cargar ediciones base del bundle
        saveEditions(modelContext: modelContext)
        UserDefaults.standard.set(true, forKey: didPreloadKey)
        try? modelContext.save()
    }

    func loadAndSaveRoles(modelContext: ModelContext) {
        // 2. Pre-cargar todos los roles posibles (si tu modelo lo requiere aparte)
        for role in loadPredefinedRoles() {
            // 1. Crea roleEntity sin specials
            _ = RoleDefinition.upsert(
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
                modelContext: modelContext
            )
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

            let metaEntity = EditionMeta.upsert(id: metaStruct.id,
                                                name: metaStruct.name,
                                                author: metaStruct.author,
                                                imageName: editionSummary.imageName,
                                                firstNight: metaStruct.firstNight,
                                                otherNight: metaStruct.otherNight,
                                                modelContext: modelContext)

            var roleEntities: [RoleDefinition] = []

            for r in roles {
                // 1. Busca si ya existe un role con ese id:
                let roleEntity = RoleDefinition.upsert(id: r.id,
                                                       name: r.name,
                                                       team: r.team,
                                                       ability: r.ability,
                                                       setup: r.setup,
                                                       iconName: r.iconName,
                                                       reminders: r.reminders,
                                                       remindersGlobal: r.remindersGlobal,
                                                       firstNightReminder: r.firstNightReminder,
                                                       otherNightReminder: r.otherNightReminder,
                                                       modelContext: modelContext)
                roleEntities.append(roleEntity)
            }

            let allStoredJinxes: [Jinx]
            do {
                allStoredJinxes = try modelContext.fetch(FetchDescriptor<Jinx>())
            } catch {
                allStoredJinxes = []
            }
            let roleIdsInEdition = Set(roleEntities.map { $0.id })
            let applicableJinxes = allStoredJinxes.filter { jinx in
                Set(jinx.roles).isSubset(of: roleIdsInEdition)
            }

            _ = EditionData.upsert(id: metaEntity.id, meta: metaEntity, characters: roleEntities, jinxes: applicableJinxes, modelContext: modelContext)
        }
    }


    func loadAndSaveJinxes(modelContext: ModelContext) {
        for jinxModel in loadJinxes() {
            // Busca en el modelo si ya existe jinx con este id (para evitar duplicados)
            _ = Jinx.upsert(
                id: jinxModel.id,
                roles: jinxModel.roles,
                description: jinxModel.desc,
                image: jinxModel.image,
                modelContext: modelContext
            )
        }
    }

    func loadJinxes() -> [JinxModel] {
        guard let url = Bundle.main.url(forResource: "jinxes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let metaData = try? JSONSerialization.data(withJSONObject: raw),
              let metaStruct = try? JSONDecoder().decode([JinxModel].self, from: metaData)

        else { return [] }

        return metaStruct
    }
}
