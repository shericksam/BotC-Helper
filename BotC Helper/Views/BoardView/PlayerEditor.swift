//
//  PlayerEditor.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct PlayerEditor: View {
    @Binding var player: Player
    @State var status: PlayerStatusPerDay
    var onSave: (PlayerStatusPerDay, [Int: String]) -> Void
    @Environment(\.dismiss) var dismiss
    var isMe: Bool

    var totalDays: Int
    var statusesByDay: [PlayerStatusPerDay]
    var currentDayIndex: Int

    @State var localPersonalNotes: [Int: String] = [:]

    init(
        player: Binding<Player>,
        status: PlayerStatusPerDay,
        onSave: @escaping (PlayerStatusPerDay, [Int: String]) -> Void,
        isMe: Bool,
        totalDays: Int,
        statusesByDay: [PlayerStatusPerDay],
        currentDayIndex: Int
    ) {
        self._player = player
        self._status = State(initialValue: status)
        self.onSave = onSave
        self.isMe = isMe
        self.totalDays = totalDays
        self.statusesByDay = statusesByDay
        self.currentDayIndex = currentDayIndex
        self._localPersonalNotes = State(initialValue: player.wrappedValue.personalNotes)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Datos del Jugador") {
                    TextField("Nombre", text: $player.name)
                    TextField("Claim (rol declarado)", text: $player.claim)
                }
                Section("Acciones (día actual)") {
                    Toggle("Votó", isOn: $status.voted)
                    Toggle("Nominó", isOn: $status.nominated)
                    Toggle("Muerto", isOn: $status.dead)
                }
                Section("Notas Día actual") {
                    TextEditor(text: $status.notes)
                        .frame(height: 80)
                }
                Section("Notas y Acciones por Día") {
                    ForEach(0..<totalDays, id: \.self) { dayIdx in
                        let s = statusesByDay[dayIdx]
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Día \(dayIdx + 1)")
                                    .font(.headline)
                                // Estados de ese día:
                                if s.voted {
                                    Label("Votó", systemImage: "checkmark.circle")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.green)
                                }
                                if s.nominated {
                                    Label("Nominó", systemImage: "hand.point.up.left.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.blue)
                                }
                                if s.dead {
                                    Label("Muerto", systemImage: "xmark")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.red)
                                }
                            }
                            TextEditor(
                                text: Binding(
                                    get: { localPersonalNotes[dayIdx] ?? "" },
                                    set: { localPersonalNotes[dayIdx] = $0 }
                                )
                            )
                            .frame(height: dayIdx == currentDayIndex ? 100 : 60)
                            .background(dayIdx == currentDayIndex ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Editar Jugador \(player.seatNumber)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(status, localPersonalNotes)
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
