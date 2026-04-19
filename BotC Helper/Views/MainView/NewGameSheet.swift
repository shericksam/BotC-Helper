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
    @Query(sort: \Friend.name) var friends: [Friend]

    @State private var editionSelected: EditionData?
    var onStart: (BoardState) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var playerCount = 5
    @State private var yourSeat = 1
    @State private var playerNames: [Int: String] = [:]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(MSG("new_game_players_section"))) {
                    Stepper(
                        MSG("new_game_players_stepper", playerCount),
                        value: $playerCount,
                        in: 5...15
                    )
                    .onChange(of: playerCount) { _, _ in
                        yourSeat = min(yourSeat, playerCount)
                    }
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

                Section(header: Text(MSG("new_game_seats_section"))) {
                    ForEach(1...playerCount, id: \.self) { seat in
                        SeatNameRow(
                            seat: seat,
                            name: Binding(
                                get: { playerNames[seat] ?? "" },
                                set: { playerNames[seat] = $0 }
                            ),
                            friends: friends,
                            usedNames: Set(playerNames.filter { $0.key != seat }.values.filter { !$0.isEmpty })
                        )
                    }
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
                    name: playerNames[i] ?? "",
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
                edition: chosenEdition
            )
            modelContext.insert(newGame)
            onStart(newGame)
        }
    }
}

private struct SeatNameRow: View {
    let seat: Int
    @Binding var name: String
    let friends: [Friend]
    let usedNames: Set<String>

    var availableFriends: [Friend] {
        friends.filter { !usedNames.contains($0.name) }
    }

    var body: some View {
        HStack {
            Text(MSG("new_game_seat_picker", seat))
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)
            TextField(MSG("new_game_seat_name_placeholder"), text: $name)
            if !friends.isEmpty {
                Menu {
                    if availableFriends.isEmpty {
                        Text(MSG("friends_all_assigned"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableFriends) { friend in
                            Button(friend.name) { name = friend.name }
                        }
                    }
                    if !name.isEmpty {
                        Divider()
                        Button(MSG("new_game_clear_name"), role: .destructive) { name = "" }
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(availableFriends.isEmpty ? .secondary : .accentColor)
                }
            }
        }
    }
}

#Preview {
    NewGameSheet(onStart: { _ in print("Started game!") })
}
