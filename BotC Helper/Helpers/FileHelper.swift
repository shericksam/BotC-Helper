//
//  FileHelper.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func suggestedFileName(playersCount : Int) -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMddyyyy'T'HH:mm:ss" // "Dec03"
    let dateString = formatter.string(from: date)
    return MSG("save_game", "\(dateString)-\(playersCount)")
}

func loadBoardState(fileName: String) -> BoardStateModel? {
    let url = getDocumentsDirectory().appendingPathComponent(fileName + ".json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(BoardStateModel.self, from: data)
}

func loadEdition(from url: URL) throws -> EditionDataModel {
    let array = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
    let meta = try JSONDecoder().decode(EditionMetaModel.self, from: JSONSerialization.data(withJSONObject: array[0]))
    let chars = try array.dropFirst().map {
        try JSONDecoder().decode(RoleDefinitionModel.self, from: JSONSerialization.data(withJSONObject: $0))
    }
    return EditionDataModel(meta: meta, characters: chars)
}

func loadPredefinedRoles() -> [RoleDefinitionModel] {
    guard let url = Bundle.main.url(forResource: "roles-combined", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let roles = try? JSONDecoder().decode([RoleDefinitionModel].self, from: data)
    else { return [] }
    return roles
}

func loadEditionDetails(_ edition: EditionSummaryModel) -> EditionDataModel? {
    if let url = editionURL(for: edition),
       let loaded = try? loadEdition(from: url) {
        return loaded
    } else {
        return nil
    }
}


func editionURL(for summary: EditionSummaryModel) -> URL? {
    if summary.isFromBundle {
        // Elimina el ".json" para buscarlo en el bundle
        let base = summary.fileName.replacingOccurrences(of: ".json", with: "")
        return Bundle.main.url(forResource: base, withExtension: "json")
    } else {
        // Document directory, nombre exacto
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(summary.fileName)
    }
}

func mockLoadEditionDetails(edition: EditionSummaryModel) -> EditionDataModel? {
    if let url = Bundle.main.url(forResource: edition.fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json"),
       let loaded = try? loadEdition(from: url) {
        return loaded
    } else {
        return nil
        // Maneja error de carga aquí si quieres
    }
}
