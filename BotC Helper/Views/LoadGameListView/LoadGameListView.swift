//
//  LoadGameListView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct LoadGameListView: View {
    @Query(sort: \BoardState.suggestedName) var allGames: [BoardState]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var selectedGame: BoardState?
    var onLoad: (BoardState) -> Void

    var body: some View {
        NavigationView {
            VStack {
                if allGames.isEmpty {
                    Text("No hay partidas guardadas.")
                } else {
                    List {
                        ForEach(allGames) { game in
                            Button(action: {
                                onLoad(game)
                                dismiss()
                            }) {
                                VStack(alignment: .leading) {
                                    Text(game.suggestedName)
                                        .font(.headline)
                                    if let editionName = game.edition?.meta.name {
                                        Text("Edición: \(editionName)").font(.subheadline)
                                    }
                                    Text("Jugadores: \(game.players.count)")
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete(perform: deleteGames)
                    }
                }
            }
            .navigationTitle("Partidas Anteriores")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    func deleteGames(at offsets: IndexSet) {
        for idx in offsets {
            let game = allGames[idx]
            modelContext.delete(game)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BoardState.self, configurations: config)
    let context = ModelContext(container)
    // Prepara datos mock:
    let edition = EditionData(
        meta: EditionMeta(
            id: "tb",
            name: "Trouble Brewing",
            author: "Steven Medway",
            firstNight: ["dusk"],
            otherNight: ["dawn"]
        ),
        characters: []
    )
    let players = (1...3).map { i in Player(seatNumber: i, name: "Jugador \(i)") }
    let game = BoardState(
        suggestedName: "Partida Mock",
        players: players,
        currentDay: 0,
        config: GameConfig(numPlayers: 3, numTownsfolk: 1, numOutsider: 1, numMinions: 1, numDemon: 0),
        edition: edition
    )
    context.insert(game)
    // Retorna la vista en un environment SwiftData
    return LoadGameListView(onLoad: { _ in })
        .modelContainer(container)
}
