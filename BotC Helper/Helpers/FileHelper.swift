//
//  FileHelper.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

func loadDefaultEditionIfNeeded(modelContext: ModelContext) async throws {
    let fetch = FetchDescriptor<Edition>()
    let editions = try modelContext.fetch(fetch)
    if !editions.isEmpty { return } // Ya hay ediciones, no hacer nada

    guard let url = Bundle.main.url(forResource: "editions_trouble_brewing", withExtension: "json"),
          let data = try? Data(contentsOf: url) else { return }

    let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any] ?? []

    // Buscamos el _meta
    guard let metaDict = jsonArray.first as? [String: Any],
          let metaData = try? JSONSerialization.data(withJSONObject: metaDict),
          let meta = try? JSONDecoder().decode(RawEdition.self, from: metaData) else { return }

    // Los demás son personajes
    let rawCharacters = Array(jsonArray.dropFirst())
        .compactMap { (entry) -> RawCharacter? in
            guard let dict = entry as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let chr = try? JSONDecoder().decode(RawCharacter.self, from: data)
            else { return nil }
            return chr
        }

    // Crea personajes como entidades SwiftData
    let characterEntities: [Character] = rawCharacters.map { rc in
        Character(
            id: rc.id,
            name: rc.name,
            team: rc.team,
            ability: rc.ability,
            setup: rc.setup ?? false,
            images: rc.image ?? [],
            reminders: rc.reminders,
            firstNightReminder: rc.firstNightReminder,
            otherNightReminder: rc.otherNightReminder
        )
    }
    // Puedes tener una entidad Script (guión) por edición (o solo uno principal)
    let script = Script(
        id: meta.id + "_main",
        name: "Guion principal",
        characters: characterEntities
    )
    let edition = Edition(
        id: meta.id,
        name: meta.name,
        nightOrderFirst: meta.firstNight,
        nightOrderOther: meta.otherNight,
        scripts: [script]
    )
    modelContext.insert(edition)
}

func saveBoardState(_ board: BoardState, fileName: String) {
    let url = getDocumentsDirectory().appendingPathComponent(fileName + ".json")
    do {
        let data = try JSONEncoder().encode(board)
        try data.write(to: url)
        print("BoardState guardado correctamente.")
    } catch {
        print("Error al guardar BoardState: \(error)")
    }
}

func loadBoardState() -> BoardState? {
    let url = getDocumentsDirectory().appendingPathComponent("saved_board.json")
    do {
        let data = try Data(contentsOf: url)
        let board = try JSONDecoder().decode(BoardState.self, from: data)
        return board
    } catch {
        print("Error al cargar BoardState: \(error)")
        return nil
    }
}

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func suggestedFileName(for board: BoardState) -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMdd" // "Dec03"
    let dateString = formatter.string(from: date)
    return "\(dateString)-\(board.players.count)P"
}

func loadBoardState(fileName: String) -> BoardState? {
    let url = getDocumentsDirectory().appendingPathComponent(fileName + ".json")
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(BoardState.self, from: data)
}
