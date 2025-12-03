//
//  PlayerEditor.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct PlayerEditor: View {
    @Binding var player: Player               // ¡Ahora se recibe binding del jugador!
    @State var status: PlayerStatusPerDay     // Status de este día
    var onSave: (PlayerStatusPerDay) -> Void
    @Environment(\.dismiss) var dismiss
//    var isMe: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Datos del Jugador") {
                    TextField("Nombre", text: $player.name)
                    TextField("Claim (rol declarado)", text: $player.claim)
                }
                Section("Acciones") {
                    Toggle("Votó", isOn: $status.voted)
                    Toggle("Nominó", isOn: $status.nominated)
                    Toggle("Muerto", isOn: $status.dead)
                }
                Section("Notas") {
                    TextEditor(text: $status.notes)
                        .frame(height: 80)
                }
            }
            .navigationTitle("Editar Jugador \(player.seatNumber)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(status)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
