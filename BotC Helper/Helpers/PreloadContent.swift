//
//  PreloadContent.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation
import SwiftData

struct PreloadContent {

    // Bump this number whenever the bundled JSON data changes
    // (new roles, updated jinxes, new editions, etc.)
    // Existing users will re-run preload automatically on next launch.
    // All operations use upsert — no user data is lost.
    static let currentDataVersion = 2

    private let versionKey = "dataVersion"

    @MainActor
    func preloadDefaultEditionsAndRolesIfNeeded(modelContext: ModelContext) async {
        let storedVersion = UserDefaults.standard.integer(forKey: versionKey)
        guard storedVersion < Self.currentDataVersion else { return }

        loadAndSaveRoles(modelContext: modelContext)
        loadAndSaveJinxes(modelContext: modelContext)
        saveEditions(modelContext: modelContext)

        UserDefaults.standard.set(Self.currentDataVersion, forKey: versionKey)
        try? modelContext.save()
    }

    func loadAndSaveRoles(modelContext: ModelContext) {
        for role in loadPredefinedRoles() {
            _ = RoleDefinition.upsert(
                id: role.id,
                name: role.name,
                team: role.team,
                ability: role.ability,
                setup: role.setup,
                reminders: role.reminders,
                remindersGlobal: role.remindersGlobal,
                firstNightReminder: role.firstNightReminder,
                otherNightReminder: role.otherNightReminder,
                edition: nil,
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

            let metaEntity = EditionMeta.upsert(
                id: metaStruct.id,
                name: metaStruct.name,
                author: metaStruct.author,
                imageName: editionSummary.imageName,
                firstNight: metaStruct.firstNight,
                otherNight: metaStruct.otherNight,
                modelContext: modelContext
            )

            let newEditionData = EditionData.upsert(
                id: metaEntity.id, meta: metaEntity,
                characters: [], jinxes: [],
                modelContext: modelContext
            )

            var roleEntities: [RoleDefinition] = []
            for r in roles {
                let roleEntity = RoleDefinition.upsert(
                    id: r.id,
                    name: r.name,
                    team: r.team,
                    ability: r.ability,
                    setup: r.setup,
                    reminders: r.reminders,
                    remindersGlobal: r.remindersGlobal,
                    firstNightReminder: r.firstNightReminder,
                    otherNightReminder: r.otherNightReminder,
                    edition: newEditionData,
                    modelContext: modelContext
                )
                roleEntities.append(roleEntity)
            }

            let allStoredJinxes: [Jinx] = (try? modelContext.fetch(FetchDescriptor<Jinx>())) ?? []
            let roleIdsInEdition = Set(roleEntities.map { $0.id })
            let applicableJinxes = allStoredJinxes.filter { Set($0.roles).isSubset(of: roleIdsInEdition) }
            newEditionData.characters = roleEntities
            applicableJinxes.forEach { $0.editions.append(newEditionData) }
            newEditionData.jinxes = applicableJinxes
        }
    }

    func loadAndSaveJinxes(modelContext: ModelContext) {
        for jinxModel in loadJinxes() {
            _ = Jinx.upsert(
                id: jinxModel.id,
                roles: jinxModel.roles,
                description: jinxModel.desc,
                image: jinxModel.image,
                edition: nil,
                modelContext: modelContext
            )
        }
    }

    func loadJinxes() -> [JinxModel] {
        guard let url = Bundle.main.url(forResource: "jinxes-combined", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let metaData = try? JSONSerialization.data(withJSONObject: raw),
              let metaStruct = try? JSONDecoder().decode([JinxModel].self, from: metaData)
        else { return [] }
        return metaStruct
    }
}
