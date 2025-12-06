//
//  NewGameSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct NewGameSheet: View {
    @State var editions: [EditionSummary] = EditionSummary.defaultEditions
    @State var editionSelected: EditionSummary = EditionSummary.defaultEditions.first!
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

                Section(header: Text("Edition")) {
                    Picker("Nombre", selection: $editionSelected) {
                        ForEach(editions, id: \.self) { editions in
                            Text("\(editions.name)").tag(editions)
                        }
                    }
                }
            }
            .navigationTitle("Nueva Partida")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Iniciar") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            let players = (1...playerCount).map { i in
                                Player(seatNumber: i, name: "", claim: "", isMe: (i == yourSeat))
                            }
                            // Día 0: todos vivos, nadie votó
                            let day0 = players.map { p in PlayerStatusPerDay(seatNumber: p.seatNumber) }
                            let config = getConfigForPlayerCount(playerCount)
                            onStart(BoardState(players: players,
                                               days: [day0],
                                               currentDay: 0,
                                               config: config,
                                               edition: loadEditionDetails(editionSelected)))
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: { dismiss() })
                }
            }
        }
    }

    func loadEditionDetails(_ edition: EditionSummary) -> EditionData? {
        if let url = Bundle.main.url(forResource: edition.fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json"),
           let loaded = try? loadEdition(from: url) {
            return loaded
        } else {
            return nil
        }
    }
}

#Preview {
    NewGameSheet(onStart: { _  in print("Started game!")})
}
