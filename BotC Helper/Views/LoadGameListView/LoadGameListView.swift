//
//  LoadGameListView.swift
//  BotC Helper
//

import SwiftUI
import SwiftData

struct LoadGameListView: View {
    @Query(sort: \BoardState.createdAt, order: .reverse) var allGames: [BoardState]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var settingWinnerFor: BoardState? = nil
    var onLoad: (BoardState) -> Void

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationView {
            Group {
                if allGames.isEmpty {
                    ContentUnavailableView(
                        MSG("no_saved_games"),
                        systemImage: "clock.arrow.circlepath"
                    )
                } else {
                    List {
                        ForEach(allGames) { game in
                            GameCard(game: game, dateFormatter: dateFormatter) {
                                onLoad(game)
                                dismiss()
                            } onSetWinner: {
                                settingWinnerFor = game
                            }
                        }
                        .onDelete(perform: deleteGames)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(MSG("previous_games_title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("close")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(item: $settingWinnerFor) { game in
                WinnerPickerSheet(game: game)
            }
        }
    }

    func deleteGames(at offsets: IndexSet) {
        for idx in offsets { modelContext.delete(allGames[idx]) }
        try? modelContext.save()
    }
}

// MARK: - Game Card

private struct GameCard: View {
    @Bindable var game: BoardState
    let dateFormatter: DateFormatter
    let onLoad: () -> Void
    let onSetWinner: () -> Void

    private var aliveCount: Int {
        game.players.filter { player in
            !(player.statuses.last?.dead ?? false)
        }.count
    }

    var body: some View {
        Button(action: onLoad) {
            VStack(alignment: .leading, spacing: 10) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dateFormatter.string(from: game.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let edition = game.edition {
                            Text(edition.meta.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                        } else {
                            Text(MSG("no_edition"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    winnerBadge
                }

                // Stats row
                HStack(spacing: 16) {
                    statPill(icon: "person.3.fill", value: "\(game.players.count)", color: .blue)
                    statPill(icon: "heart.fill", value: "\(aliveCount)", color: .green)
                    statPill(icon: "sun.max.fill", value: "D\(game.currentDay + 1)", color: .orange)
                }

                // Author if available
                if let author = game.edition?.meta.author, !author.isEmpty {
                    Text(MSG("edition_author", author))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                onSetWinner()
            } label: {
                Label(MSG("game_set_winner"), systemImage: "trophy.fill")
            }
            .tint(.yellow)
        }
    }

    @ViewBuilder
    private var winnerBadge: some View {
        switch game.winner {
        case "good":
            Label(MSG("game_winner_good"), systemImage: "sun.max.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .clipShape(Capsule())
        case "evil":
            Label(MSG("game_winner_evil"), systemImage: "moon.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .clipShape(Capsule())
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Winner Picker Sheet

private struct WinnerPickerSheet: View {
    @Bindable var game: BoardState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Button {
                    game.winner = "good"
                    try? modelContext.save()
                    dismiss()
                } label: {
                    HStack {
                        Label(MSG("game_winner_good"), systemImage: "sun.max.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        if game.winner == "good" {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }

                Button {
                    game.winner = "evil"
                    try? modelContext.save()
                    dismiss()
                } label: {
                    HStack {
                        Label(MSG("game_winner_evil"), systemImage: "moon.fill")
                            .foregroundColor(.red)
                        Spacer()
                        if game.winner == "evil" {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }

                Button {
                    game.winner = nil
                    try? modelContext.save()
                    dismiss()
                } label: {
                    HStack {
                        Label(MSG("game_winner_none"), systemImage: "minus.circle")
                            .foregroundColor(.secondary)
                        Spacer()
                        if game.winner == nil {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle(MSG("game_set_winner"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("close")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BoardState.self, configurations: config)
    let context = ModelContext(container)
    let edition = EditionData(
        meta: EditionMeta(id: "tb", name: "Trouble Brewing", author: "Steven Medway", firstNight: [], otherNight: []),
        characters: []
    )
    let players = (1...7).map { i in
        let p = Player(seatNumber: i, name: "Jugador \(i)")
        p.statuses = [PlayerStatus(dayIndex: 0, seatNumber: i, dead: i > 5)]
        return p
    }
    let game = BoardState(
        suggestedName: "Partida Mock",
        players: players,
        currentDay: 2,
        config: GameConfig(numPlayers: 7, numTownsfolk: 5, numOutsider: 0, numMinions: 1, numDemon: 1),
        edition: edition
    )
    game.winner = "evil"
    context.insert(game)
    return LoadGameListView(onLoad: { _ in }).modelContainer(container)
}
