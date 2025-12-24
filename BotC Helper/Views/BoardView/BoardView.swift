//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct EditingIndex: Identifiable {
    var id: Int { value }
    var value: Int
}

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var board: BoardState
    @State private var editingPlayer: Player?
    @State private var isVotingPhase = false
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayerIdx: Int? = nil
    @State private var showResetAlert = false
    @Environment(\.modelContext) private var modelContext

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack {
            Picker(MSG("board_day", board.currentDay + 1), selection: $board.currentDay) {
                ForEach(0..<board.totalDays, id: \.self) { idx in
                    Text(MSG("board_day", idx + 1)).tag(idx)
                }
            }
            .pickerStyle(.segmented)
            .onAppear {
                let appearance = UISegmentedControl.appearance()

                appearance.backgroundColor = UIColor.systemGray5

                appearance.selectedSegmentTintColor = UIColor.white

                let normalTextAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.systemGray
                ]
                appearance.setTitleTextAttributes(normalTextAttributes, for: .normal)

                let selectedTextAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.darkGray
                ]
                appearance.setTitleTextAttributes(selectedTextAttributes, for: .selected)
            }
            .padding(.vertical)

            Spacer()

            ZStack {
                playerGridView()

                // --- Configuración central ---
                VStack {
                    if isVotingPhase {
                        VStack {
                            Image(systemName: "flag.pattern.checkered")
                            Text(MSG("board_voting"))
                        }.onTapGesture {
                            isVotingPhase.toggle()
                        }
                    }
                    Button(MSG("board_new_day")) { addDay() }
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 5)
                    if let edition = board.edition {
                        Button(edition.meta.name) {
                            showDetail.toggle()
                        }
                        .font(.title2)
                    }
                    Text(MSG("board_players_count", board.players.count)).font(.title3).bold()
                    Text(MSG("board_townsfolk", board.config.numTownsfolk)).font(.body)
                    Text(MSG("board_outsider", board.config.numOutsider)).font(.body)
                    Text(MSG("board_minion", board.config.numMinions)).font(.body)
                    Text(MSG("board_demon", board.config.numDemon)).font(.body)
//                    NavigationLink(destination: GPTAssistantView(board: board)) {
//                        Label("Análisis AI", systemImage: "bolt.circle.fill")
//                    }
                }
                .foregroundColor(.white)
                .padding()
            }
        }
        .background(
            Image("background-side")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(MSG("board_save"), systemImage: "square.and.arrow.down") {
                        try? modelContext.save()
                    }
                    Button(MSG("board_add_player"), systemImage: "person.crop.circle.badge.plus") {
                        addPlayer()
                    }
                    Button(isVotingPhase ? MSG("board_stop_voting") : MSG("board_start_voting"),
                           systemImage: isVotingPhase ? "flag.filled.and.flag.crossed" : "flag.pattern.checkered") {
                        isVotingPhase.toggle()
                    }
                    Button(MSG("board_clear_votes"), systemImage: "checkmark.circle") { clearAllVotes() }
                    Button(MSG("board_clear_nominations"), systemImage: "exclamationmark.bubble") { clearAllNominations() }
                    Button(MSG("board_new_game"), systemImage: "arrow.clockwise") { showResetAlert = true }
                        .tint(.red)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            }
        }
        .onDisappear {
            try? modelContext.save()
        }
        .alert(MSG("board_reset_title"), isPresented: $showResetAlert) {
            Button(MSG("board_reset_button"), role: .destructive) {
                resetBoardForNewGame()
            }
            Button(MSG("board_reset_cancel"), role: .cancel) { }
        } message: {
            Text(MSG("board_reset_message"))
        }
        .navigationDestination(isPresented: $showDetail) {
            if let data = board.edition {
                EditionDetailView(editionMeta: data)
            } else {
                EmptyView()
            }
        }
        .sheet(item: $editingPlayer) { player in
            if
               let status = player.statuses[safe: board.currentDay] {
                PlayerEditor(
                    player: player,
                    status: status,
                    onSave: { _, _ in
                        try? modelContext.save()
                        editingPlayer = nil
                    },
                    isMe: player.isMe,
                    totalDays: board.players.first?.statuses.count ?? 1,
                    statusesByDay: player.statuses,
                    currentDayIndex: board.currentDay,
                    roles: board.edition?.characters ?? []
                )
            } else {
                Text("No player to edit")
            }
        }
    }

    // ------- Funciones clave --------

    func addDay() {
        let newDayIndex = (board.players.first?.statuses.count ?? 0)
        for player in board.players {
            let prev = player.statuses[board.currentDay]
            player.statuses.append(PlayerStatus(dayIndex: newDayIndex,
                                                seatNumber: prev.seatNumber,
                                                voted: false,
                                                nominated: false,
                                                dead: prev.dead,
                                                claim: prev.claim,
                                                notes: "")
            )
        }
        clearAllVotes()
        clearAllNominations()
        board.currentDay = newDayIndex
        try? modelContext.save()
    }

    func addPlayer() {
        let seatNumber = board.players.count + 1
        let totalDays = board.players.first?.statuses.count ?? 1
        let newPlayer = Player(
            seatNumber: seatNumber,
            name: "",
            isMe: false,
            statuses: (0..<totalDays).map { PlayerStatus(dayIndex: $0) }
        )
        board.players.append(newPlayer)
        try? modelContext.save()
    }

    func clearAllVotes() {
        for player in board.players {
            for status in player.statuses {
                status.voted = false
            }
        }
        try? modelContext.save()
    }

    func clearAllNominations() {
        for player in board.players {
            for status in player.statuses {
                status.nominated = false
            }
        }
        try? modelContext.save()
    }

    func resetBoardForNewGame() {
        for player in board.players {
            player.claimRoleId = nil
            player.claimManual = ""
            player.personalNotes.removeAll()
            player.statuses = [PlayerStatus(dayIndex: 0)]
        }
        board.currentDay = 0
        board.suggestedName = suggestedFileName(playersCount: board.players.count)
        try? modelContext.save()
    }

    @ViewBuilder
    func playerGridView() -> some View {
        GeometryReader { geo in
            let orderedPlayers = board.players.sorted { $0.seatNumber < $1.seatNumber }
            let positions = squarePerimeterPositions(count: orderedPlayers.count, in: geo.size)
            ZStack {
                ForEach(Array(orderedPlayers.enumerated()), id: \.1.id) { idx, player in
                    let pos = positions[idx]
                    if let status = player.statuses[safe: board.currentDay] {
                        PlayerCircle(
                            player: player,
                            status: status,
                            isMe: player.isMe,
                            roles: board.edition?.characters ?? [],
                            onTap: {
                                if isVotingPhase {
                                    player.statuses[safe: board.currentDay]?.voted.toggle()
                                    try? modelContext.save()
                                } else {
                                    editingPlayer = player
                                }
                            }
                        )
                        .position(pos + (draggedPlayerIdx == idx ? dragOffset : .zero))
                        .zIndex(draggedPlayerIdx == idx ? 1 : 0)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.2)
                                .onEnded { _ in
                                    draggedPlayerIdx = idx
                                    dragOffset = .zero
                                }
                                .sequenced(before: DragGesture())
                                .onChanged { value in
                                    switch value {
                                    case .second(true, let drag?):
                                        dragOffset = drag.translation
                                    default:
                                        break
                                    }
                                }
                                .onEnded { _ in
                                    if let draggedIdx = draggedPlayerIdx {
                                        let newPosition = positions[draggedIdx] + dragOffset
                                        if let targetIdx = positions.enumerated().min(by: {
                                            distance($0.element, newPosition) < distance($1.element, newPosition)
                                        })?.offset, targetIdx != draggedIdx {

                                            // SWAP solo los seatNumbers:
                                            let a = orderedPlayers[draggedIdx]
                                            let b = orderedPlayers[targetIdx]
                                            let tmp = a.seatNumber
                                            a.seatNumber = b.seatNumber
                                            b.seatNumber = tmp

                                            // ⚡️ Ahora REORDENA el array principal del BoardState:
                                            board.players.sort { $0.seatNumber < $1.seatNumber }

                                            try? modelContext.save()
                                        }
                                        draggedPlayerIdx = nil
                                        dragOffset = .zero
                                    }
                                }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, isRegular ? 80 : 40)
        .padding(.vertical, isRegular ? 80 : 50)
    }

    // Utilidad
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }

    func squarePerimeterPositions(count: Int, in size: CGSize) -> [CGPoint] {
        let sides = 4
        let perSide = max(1, count / sides)
        let remainder = count % sides

        var result: [CGPoint] = []
        var placed = 0

        for side in 0..<sides {
            var nOnThisSide = perSide
            if side < remainder { nOnThisSide += 1 }
            for i in 0..<nOnThisSide {
                let fraction = nOnThisSide == 1 ? 0.5 : CGFloat(i) / CGFloat(nOnThisSide - 0)
                var x: CGFloat = 0, y: CGFloat = 0
                switch side {
                case 0: // Top (left to right)
                    x = fraction
                    y = 0.0
                case 1: // Right (top to bottom)
                    x = 1.0
                    y = fraction
                case 2: // Bottom (right to left)
                    x = 1.0 - fraction
                    y = 1.0
                case 3: // Left (bottom to top)
                    x = 0.0
                    y = 1.0 - fraction
                default: break
                }
                result.append(CGPoint(x: x * size.width, y: y * size.height))
                placed += 1
                if placed == count { return result }
            }
        }
        return result
    }
}

#Preview {
    // Crea modelo in-memory
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BoardState.self, configurations: config)
    let context = ModelContext(container)
    // MOCK:
    let playerCount = 20
    let names = ["Ana", "Bernardo", "Erick", "Fabian", "Carlos", "Dio", "Pedro", "Quike", "Ricardo", "Sergio", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera", "Ricardo", "Sandro", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera"]
    let players = (1...playerCount).map {
        Player(seatNumber: $0,
               name: names[$0],
               claimRoleId: rolesExample[$0].nameLocalized(),
               statuses: [
            PlayerStatus(dayIndex: 0, seatNumber: $0)
        ])
    }
    // Día 0: todos vivos, nadie votó
    let newConfig = getConfigForPlayerCount(playerCount)
    let configGame = GameConfig(numPlayers: newConfig.numPlayers,
                                numTownsfolk: newConfig.numTownsfolk,
                                numOutsider: newConfig.numOutsider,
                                numMinions: newConfig.numMinions,
                                numDemon: newConfig.numDemon)
    let meta = EditionMeta(id: "test", name: "Tests", author: "Me")
    let game = BoardState(
        suggestedName: "Demo",
        players: players,
        currentDay: 0,
        config: configGame,
        edition: EditionData(meta: meta, characters: rolesExample)
    )
    context.insert(game)
    return BoardView(board: game)
        .modelContainer(container)
}

let rolesExample = [
    RoleDefinition(id: "grandmother", name: ["es": "grandmother"]),
    RoleDefinition(id: "acrobat", name: ["es": "acrobat"]),
    RoleDefinition(id: "fortuneteller", name: ["es": "fortuneteller"]),
    RoleDefinition(id: "steward", name: ["es": "steward"]),
    RoleDefinition(id: "balloonist", name: ["es": "balloonist"]),
    RoleDefinition(id: "mayor", name: ["es": "mayor"]),
    RoleDefinition(id: "alchemist", name: ["es": "alchemist"]),
    RoleDefinition(id: "alsaahir", name: ["es": "alsaahir"]),
    RoleDefinition(id: "amnesiac", name: ["es": "amnesiac"]),
    RoleDefinition(id: "artist", name: ["es": "artist"]),
    RoleDefinition(id: "atheist", name: ["es": "atheist"]),
    RoleDefinition(id: "librarian", name: ["es": "librarian"]),
    RoleDefinition(id: "fool", name: ["es": "fool"]),
    RoleDefinition(id: "knight", name: ["es": "knight"]),
    RoleDefinition(id: "cannibal", name: ["es": "cannibal"]),
    RoleDefinition(id: "huntsman", name: ["es": "huntsman"]),
    RoleDefinition(id: "bountyhunter", name: ["es": "bountyhunter"]),
    RoleDefinition(id: "gossip", name: ["es": "gossip"]),
    RoleDefinition(id: "chef", name: ["es": "chef"]),
    RoleDefinition(id: "courtier", name: ["es": "courtier"]),
    RoleDefinition(id: "seamstress", name: ["es": "seamstress"]),
    RoleDefinition(id: "cultleader", name: ["es": "cultleader"]),
    RoleDefinition(id: "poppygrower", name: ["es": "poppygrower"]),
    RoleDefinition(id: "empath", name: ["es": "empath"]),
    RoleDefinition(id: "snakecharmer", name: ["es": "snakecharmer"]),
    RoleDefinition(id: "undertaker", name: ["es": "undertaker"]),
    RoleDefinition(id: "savant", name: ["es": "savant"]),
    RoleDefinition(id: "exorcist", name: ["es": "exorcist"]),
    RoleDefinition(id: "slayer", name: ["es": "slayer"]),
    RoleDefinition(id: "philosopher", name: ["es": "philosopher"]),
    RoleDefinition(id: "general", name: ["es": "general"]),
    RoleDefinition(id: "farmer", name: ["es": "farmer"]),
    RoleDefinition(id: "ravenkeeper", name: ["es": "ravenkeeper"]),
    RoleDefinition(id: "pixie", name: ["es": "pixie"]),
    RoleDefinition(id: "engineer", name: ["es": "engineer"]),
    RoleDefinition(id: "investigator", name: ["es": "investigator"]),
    RoleDefinition(id: "washerwoman", name: ["es": "washerwoman"]),
    RoleDefinition(id: "lycanthrope", name: ["es": "lycanthrope"]),
    RoleDefinition(id: "banshee", name: ["es": "banshee"]),
    RoleDefinition(id: "gambler", name: ["es": "gambler"]),
    RoleDefinition(id: "magician", name: ["es": "magician"]),
    RoleDefinition(id: "juggler", name: ["es": "juggler"]),
    RoleDefinition(id: "sailor", name: ["es": "sailor"]),
    RoleDefinition(id: "mathematician", name: ["es": "mathematician"]),
    RoleDefinition(id: "monk", name: ["es": "monk"]),
    RoleDefinition(id: "flowergirl", name: ["es": "flowergirl"]),
    RoleDefinition(id: "choirboy", name: ["es": "choirboy"]),
    RoleDefinition(id: "noble", name: ["es": "noble"]),
    RoleDefinition(id: "oracle", name: ["es": "oracle"]),
    RoleDefinition(id: "pacifist", name: ["es": "pacifist"]),
    RoleDefinition(id: "fisherman", name: ["es": "fisherman"]),
    RoleDefinition(id: "innkeeper", name: ["es": "innkeeper"]),
    RoleDefinition(id: "predicador", name: ["es": "predicador"]),
    RoleDefinition(id: "towncrier", name: ["es": "towncrier"]),
    RoleDefinition(id: "princess", name: ["es": "princess"]),
    RoleDefinition(id: "professor", name: ["es": "professor"]),
    RoleDefinition(id: "clockmaker", name: ["es": "clockmaker"]),
    RoleDefinition(id: "king", name: ["es": "king"]),
    RoleDefinition(id: "sage", name: ["es": "sage"]),
    RoleDefinition(id: "highpriestess", name: ["es": "highpriestess"]),
    RoleDefinition(id: "tealady", name: ["es": "tealady"]),
    RoleDefinition(id: "shugenja", name: ["es": "shugenja"]),
    RoleDefinition(id: "chambermaid", name: ["es": "chambermaid"]),
    RoleDefinition(id: "soldier", name: ["es": "soldier"]),
    RoleDefinition(id: "dreamer", name: ["es": "dreamer"])
]
