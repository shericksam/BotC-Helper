//
//  NewGameSetupSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import SwiftUI
import SwiftData

struct NewGameSetupSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EditionData.id) var allEditions: [EditionData]
    @Query(sort: \Friend.name) var friends: [Friend]

    @Bindable var board: BoardState
    var onConfirm: () -> Void

    @State private var playerCount: Int
    @State private var playerNames: [Int: String]
    @State private var yourSeat: Int
    @State private var editionSelected: EditionData?

    init(board: BoardState, onConfirm: @escaping () -> Void) {
        self.board = board
        self.onConfirm = onConfirm
        let count = board.players.count
        _playerCount = State(initialValue: count)
        _yourSeat = State(initialValue: board.players.first(where: { $0.isMe })?.seatNumber ?? 1)
        _editionSelected = State(initialValue: board.edition)
        var names: [Int: String] = [:]
        for p in board.players { names[p.seatNumber] = p.name }
        _playerNames = State(initialValue: names)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(MSG("new_game_players_section"))) {
                    Stepper(
                        MSG("new_game_players_stepper", playerCount),
                        value: $playerCount,
                        in: 5...20
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
                            Text(edition.meta.name).tag(Optional(edition))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section(header: Text(MSG("new_game_seats_section"))) {
                    ForEach(1...playerCount, id: \.self) { seat in
                        SeatRow(
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
            .navigationTitle(MSG("board_new_game"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("new_game_start_button")) {
                        applyChanges()
                        dismiss()
                        onConfirm()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("new_game_cancel_button")) { dismiss() }
                }
            }
        }
    }

    private func applyChanges() {
        let existing = board.players.sorted { $0.seatNumber < $1.seatNumber }
        let existingSeats = Set(existing.map { $0.seatNumber })
        let targetSeats = Set(1...playerCount)

        // Remove players that no longer have a seat
        for player in existing where !targetSeats.contains(player.seatNumber) {
            board.players.removeAll { $0.id == player.id }
            modelContext.delete(player)
        }

        // Update/reset existing seats that remain
        for player in board.players {
            player.name = playerNames[player.seatNumber] ?? player.name
            player.isMe = (player.seatNumber == yourSeat)
            player.claimRoleId = nil
            player.claimManual = ""
            player.personalNotes = [PersonalNote(dayIndex: 0, text: "")]
            player.statuses = [PlayerStatus(dayIndex: 0, seatNumber: player.seatNumber)]
        }

        // Add new players for newly added seats
        for seat in targetSeats where !existingSeats.contains(seat) {
            let newPlayer = Player(
                seatNumber: seat,
                name: playerNames[seat] ?? "",
                isMe: (seat == yourSeat),
                personalNotes: [PersonalNote(dayIndex: 0, text: "")],
                statuses: [PlayerStatus(dayIndex: 0, seatNumber: seat)]
            )
            board.players.append(newPlayer)
        }

        board.currentDay = 0
        board.edition = editionSelected
        board.config = getConfigForPlayerCount(playerCount)
        board.suggestedName = suggestedFileName(playersCount: playerCount)
        try? modelContext.save()
    }
}

private struct SeatRow: View {
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
