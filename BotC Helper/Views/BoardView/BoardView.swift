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
    @Query(sort: \RoleDefinition.id) var allRoles: [RoleDefinition]
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var board: BoardState
    @State private var editingPlayer: Player?
    @State private var isVotingPhase = false
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayerIdx: Int? = nil
    @State private var draggedReminderId: UUID? = nil
    @State private var reminderDragOffset: CGSize = .zero
    @State private var showNewGameSetup = false
    @State private var showAddReminder = false
    @State private var boardCanvasSize: CGSize = .zero
    @Environment(\.modelContext) private var modelContext

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

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
                appearance.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .normal)
                appearance.setTitleTextAttributes([.foregroundColor: UIColor.darkGray], for: .selected)
            }
            .padding(.vertical)

            Spacer()

            ZStack {
                playerGridView()

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
                    Button(MSG("board_add_reminder"), systemImage: "tag.fill") {
                        showAddReminder = true
                    }
                    Button(isVotingPhase ? MSG("board_stop_voting") : MSG("board_start_voting"),
                           systemImage: isVotingPhase ? "flag.filled.and.flag.crossed" : "flag.pattern.checkered") {
                        isVotingPhase.toggle()
                    }
                    Button(MSG("board_clear_votes"), systemImage: "checkmark.circle") { clearAllVotes() }
                    Button(MSG("board_clear_nominations"), systemImage: "exclamationmark.bubble") { clearAllNominations() }
                    Button(MSG("board_new_game"), systemImage: "arrow.clockwise") { showNewGameSetup = true }
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
        .sheet(isPresented: $showNewGameSetup) {
            NewGameSetupSheet(board: board) { }
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderSheet(board: board, roles: board.edition?.characters ?? allRoles)
        }
        .navigationDestination(isPresented: $showDetail) {
            if let data = board.edition {
                EditionDetailView(editionMeta: data)
            } else {
                EmptyView()
            }
        }
        .sheet(item: $editingPlayer) { player in
            if let status = player.statuses.first(where: { $0.dayIndex == board.currentDay }) {
                PlayerEditor(
                    player: player,
                    status: status,
                    onSave: {
                        try? modelContext.save()
                        editingPlayer = nil
                    },
                    isMe: player.isMe,
                    totalDays: board.players.first?.statuses.count ?? 1,
                    statusesByDay: player.statuses,
                    currentDayIndex: board.currentDay,
                    roles: board.edition?.characters ?? allRoles
                )
            } else {
                Text("No player to edit")
            }
        }
    }

    // MARK: - Board layout

    @ViewBuilder
    func playerGridView() -> some View {
        GeometryReader { geo in
            let orderedPlayers = board.players.sorted { $0.seatNumber < $1.seatNumber }
            let fallbackPositions: [CGPoint] = {
                guard orderedPlayers.contains(where: { $0.posX < 0 }) else { return [] }
                return squarePerimeterPositions(count: orderedPlayers.count, in: geo.size)
            }()

            ZStack {
                ForEach(Array(orderedPlayers.enumerated()), id: \.1.id) { idx, player in
                    let basePos: CGPoint = {
                        if player.posX >= 0 {
                            return CGPoint(x: player.posX * geo.size.width,
                                           y: player.posY * geo.size.height)
                        }
                        if idx < fallbackPositions.count { return fallbackPositions[idx] }
                        return CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    }()
                    let isDragging = draggedPlayerIdx == idx

                    if let status = player.statuses.first(where: { $0.dayIndex == board.currentDay }) {
                        PlayerCircle(
                            player: player,
                            status: status,
                            isMe: player.isMe,
                            roles: board.edition?.characters ?? allRoles,
                            onTap: {
                                if isVotingPhase {
                                    player.statuses.first(where: { $0.dayIndex == board.currentDay })?.voted.toggle()
                                    try? modelContext.save()
                                } else {
                                    editingPlayer = player
                                }
                            }
                        )
                        .position(basePos + (isDragging ? dragOffset : .zero))
                        .scaleEffect(isDragging ? 1.15 : 1.0)
                        .shadow(color: isDragging ? .black.opacity(0.45) : .clear,
                                radius: isDragging ? 12 : 0, x: 0, y: isDragging ? 6 : 0)
                        .zIndex(isDragging ? 2 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isDragging)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.15)
                                .onEnded { _ in
                                    feedbackGenerator.impactOccurred()
                                    draggedPlayerIdx = idx
                                    dragOffset = .zero
                                }
                                .sequenced(before: DragGesture())
                                .onChanged { value in
                                    switch value {
                                    case .second(true, let drag?):
                                        dragOffset = drag.translation
                                    default: break
                                    }
                                }
                                .onEnded { _ in
                                    if let draggedIdx = draggedPlayerIdx {
                                        let p = orderedPlayers[draggedIdx]
                                        let currentPos: CGPoint = p.posX >= 0
                                            ? CGPoint(x: p.posX * geo.size.width, y: p.posY * geo.size.height)
                                            : (draggedIdx < fallbackPositions.count
                                                ? fallbackPositions[draggedIdx]
                                                : CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                        let newX = min(max(currentPos.x + dragOffset.width, 0), geo.size.width)
                                        let newY = min(max(currentPos.y + dragOffset.height, 0), geo.size.height)
                                        p.posX = newX / geo.size.width
                                        p.posY = newY / geo.size.height
                                        try? modelContext.save()
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            draggedPlayerIdx = nil
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                    }
                }

                // Reminder tokens overlay
                ForEach(board.reminders) { reminder in
                    let rBase = CGPoint(x: reminder.posX * geo.size.width,
                                       y: reminder.posY * geo.size.height)
                    let isRDragging = draggedReminderId == reminder.id
                    ReminderChip(text: reminder.text, color: reminder.uiColor)
                        .position(rBase + (isRDragging ? reminderDragOffset : .zero))
                        .scaleEffect(isRDragging ? 1.1 : 1.0)
                        .shadow(color: isRDragging ? .black.opacity(0.3) : .clear,
                                radius: isRDragging ? 6 : 0)
                        .zIndex(isRDragging ? 3 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRDragging)
                        .gesture(
                            LongPressGesture(minimumDuration: 0.15)
                                .onEnded { _ in
                                    feedbackGenerator.impactOccurred()
                                    draggedReminderId = reminder.id
                                    reminderDragOffset = .zero
                                }
                                .sequenced(before: DragGesture())
                                .onChanged { value in
                                    switch value {
                                    case .second(true, let drag?):
                                        reminderDragOffset = drag.translation
                                    default: break
                                    }
                                }
                                .onEnded { _ in
                                    if draggedReminderId == reminder.id {
                                        let newX = min(max(reminder.posX * geo.size.width + reminderDragOffset.width, 0), geo.size.width)
                                        let newY = min(max(reminder.posY * geo.size.height + reminderDragOffset.height, 0), geo.size.height)
                                        reminder.posX = newX / geo.size.width
                                        reminder.posY = newY / geo.size.height
                                        try? modelContext.save()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            draggedReminderId = nil
                                            reminderDragOffset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            board.reminders.removeAll(where: { $0.id == reminder.id })
                            try? modelContext.save()
                        }
                }
            }
            .onAppear {
                boardCanvasSize = geo.size
                initPositionsIfNeeded(geo.size, players: board.players.sorted { $0.seatNumber < $1.seatNumber })
            }
            .onChange(of: geo.size) { _, newSize in
                boardCanvasSize = newSize
            }
        }
        .padding(.horizontal, isRegular ? 80 : 40)
        .padding(.vertical, isRegular ? 80 : 50)
    }

    // MARK: - Helpers

    func initPositionsIfNeeded(_ size: CGSize, players: [Player]) {
        guard size.width > 0, size.height > 0 else { return }
        guard players.contains(where: { $0.posX < 0 }) else { return }
        let positions = squarePerimeterPositions(count: players.count, in: size)
        var changed = false
        for (idx, player) in players.enumerated() where player.posX < 0 {
            guard idx < positions.count else { continue }
            player.posX = positions[idx].x / size.width
            player.posY = positions[idx].y / size.height
            changed = true
        }
        if changed { try? modelContext.save() }
    }

    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }

    func squarePerimeterPositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }
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
                case 0: x = fraction; y = 0.0
                case 1: x = 1.0;      y = fraction
                case 2: x = 1.0 - fraction; y = 1.0
                case 3: x = 0.0;      y = 1.0 - fraction
                default: break
                }
                result.append(CGPoint(x: x * size.width, y: y * size.height))
                placed += 1
                if placed == count { return result }
            }
        }
        return result
    }

    // MARK: - Actions

    func addDay() {
        let newDayIndex = (board.players.first?.statuses.count ?? 0)
        for player in board.players {
            guard let prev = player.statuses.first(where: { $0.dayIndex == board.currentDay }) else { continue }
            player.statuses.append(PlayerStatus(
                dayIndex: newDayIndex,
                seatNumber: prev.seatNumber,
                voted: false,
                nominated: false,
                dead: prev.dead,
                deathType: prev.deathType,
                claim: prev.claim,
                notes: ""
            ))
            player.personalNotes.append(.init(dayIndex: newDayIndex, text: ""))
        }
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
        if boardCanvasSize != .zero {
            initPositionsIfNeeded(boardCanvasSize, players: board.players.sorted { $0.seatNumber < $1.seatNumber })
        }
        try? modelContext.save()
    }

    func clearAllVotes() {
        for player in board.players {
            for status in player.statuses { status.voted = false }
        }
        try? modelContext.save()
    }

    func clearAllNominations() {
        for player in board.players {
            for status in player.statuses { status.nominated = false }
        }
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BoardState.self, configurations: config)
    let context = ModelContext(container)
    let playerCount = 20
    let names = ["Ana", "Bernardo", "Erick", "Fabian", "Carlos", "Dio", "Pedro", "Quike", "Ricardo", "Sergio", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera", "Ricardo", "Sandro", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera"]
    let players = (1...playerCount).map {
        Player(seatNumber: $0,
               name: names[$0],
               claimRoleId: rolesExample[$0].nameLocalized(),
               statuses: [PlayerStatus(dayIndex: 0, seatNumber: $0)])
    }
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
