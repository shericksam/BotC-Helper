//
//  NewGameSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct NewGameSheet: View {
    var onStart: (BoardState) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var playerCount = 5

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cantidad de jugadores")) {
                    Stepper("\(playerCount) jugadores", value: $playerCount, in: 5...20)
                }
            }
            .navigationTitle("Nueva Partida")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Iniciar") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            let players = (1...playerCount).map {
                                Player(seatNumber: $0, name: "", claim: "")
                            }
                            // Día 0: todos vivos, nadie votó
                            let day0 = players.map { p in PlayerStatusPerDay(seatNumber: p.seatNumber) }
                            let config = getConfigForPlayerCount(playerCount)
                            onStart(BoardState(players: players, days: [day0], currentDay: 0, config: config))
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: { dismiss() })
                }
            }
        }
    }
}
#Preview {
    NewGameSheet(onStart: { _ in print("Started game!")})
}
