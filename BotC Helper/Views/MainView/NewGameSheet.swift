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
    @Query(sort: \RoleDefinition.id) var allRoles: [RoleDefinition]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(MSG("new_game_players_section"))) {
                    Stepper(
                        MSG("new_game_players_stepper", playerCount),
                        value: $playerCount,
                        in: 5...20
                    )
                }
                Section(header: Text(MSG("new_game_seat_section"))) {
                    Picker(MSG("new_game_seat_picker", yourSeat), selection: $yourSeat) {
                        ForEach(1...playerCount, id: \.self) { idx in
                            Text(MSG("new_game_seat_picker", idx)).tag(idx)
                        }
                    }
                    .pickerStyle(.wheel)
                }

                Section(header: Text(MSG("new_game_edition_section"))) {
                    Picker(MSG("new_game_picker_label"), selection: $editionSelected) {
                        Text(MSG("no_edition")).tag(nil as EditionData?)
                        ForEach(allEditions, id: \.self) { edition in
                            Text(edition.meta.name)
                                .tag(Optional(edition))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
            .navigationTitle(MSG("new_game_title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("new_game_start_button")) {
                        dismiss()
                        startGame()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("new_game_cancel_button"), action: { dismiss() })
                }
            }
        }
    }

    func startGame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let chosenEdition = editionSelected
            let players = (1...playerCount).map { i in
                Player(
                    seatNumber: i,
                    name: "",
                    claimRoleId: nil,
                    claimManual: "",
                    isMe: (i == yourSeat),
                    personalNotes: [PersonalNote(dayIndex: 0, text: "")],
                    statuses: [PlayerStatus(dayIndex: 0, seatNumber: i)]
                )
            }
            let config = getConfigForPlayerCount(playerCount)
            let newGame = BoardState(
                suggestedName: suggestedFileName(playersCount: playerCount),
                players: players,
                currentDay: 0,
                config: config,
                edition: chosenEdition ?? createDefaultEdition()
            )
            modelContext.insert(newGame)
            onStart(newGame)
        }
    }

    func createDefaultEdition() -> EditionData {
        let meta = EditionMeta(id: "non", name: MSG("no_edition"))
        return EditionData(meta: meta, characters: allRoles)
    }
}

#Preview {
    NewGameSheet(onStart: { _  in print("Started game!")})
}
