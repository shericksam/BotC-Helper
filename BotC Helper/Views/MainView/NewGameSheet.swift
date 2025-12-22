//
//  NewGameSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct NewGameSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EditionData.id) var allEditions: [EditionData]
    @State private var editionSelected: EditionData?
    var onStart: (BoardState) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var playerCount = 5
    @State private var yourSeat = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cantidad de jugadores")) {
                    Stepper("\(playerCount) jugadores", value: $playerCount, in: 5...20)
                }
                Section(header: Text("¿En qué asiento eres tú?")) {
                    Picker("Tu asiento", selection: $yourSeat) {
                        ForEach(1...playerCount, id: \.self) { idx in
                            Text("Asiento \(idx)").tag(idx)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(header: Text("Edición")) {
                    Picker("Nombre", selection: $editionSelected) {
                        ForEach(allEditions, id: \.self) { edition in
                            Text(edition.meta?.name ?? "(Sin nombre)").tag(Optional(edition))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle("Nueva Partida")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Iniciar") {
                        dismiss()
                        startGame()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: { dismiss() })
                }
            }
            .onAppear(){
                print(allEditions)
            }
        }
    }

    func startGame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Carga edition (opcionalmente, aquí solo guarda el id o clave, no el JSON completo)
            guard let editionData = editionSelected else { return }

            // Crea los jugadores
            let players = (1...playerCount).map { i in
                Player(seatNumber: i, name: "", claimRoleId: nil, claimManual: "", isMe: (i == yourSeat))
            }

            // Día 0: todos vivos, nadie votó
            let day0Statuses = players.map { p in PlayerStatus(seatNumber: p.seatNumber) }
            let day0 = GameDay(index: 0, playerStatuses: day0Statuses)

            // Config
            let config = getConfigForPlayerCount(playerCount)

            // Crea el objeto SwiftData principal
            let newGame = BoardState(
                suggestedName: suggestedFileName(playersCount: playerCount),
                players: players,
                days: [day0],
                currentDay: 0,
                config: config,
                edition: editionData
            )

            // Guarda en SwiftData
            modelContext.insert(newGame)

            onStart(newGame)
        }
    }
}

#Preview {
    NewGameSheet(onStart: { _  in print("Started game!")})
}
