//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct BoardView: View {
    @Query(sort: \RoleDefinition.id) var allRoles: [RoleDefinition]
    @Query(sort: \Jinx.id) var allJinxes: [Jinx]
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
    @State private var showInfoPanel = false
    @State private var showManageFabled = false
    @State private var boardCanvasSize: CGSize = .zero
    @State private var bundleFabled: [RoleDefinitionModel] = []
    @Environment(\.modelContext) private var modelContext

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    private var isRegular: Bool { sizeClass == .regular }

    // Jinxes where both roles are currently claimed
    var activeJinxes: [Jinx] {
        let claimedIds = Set(board.players.compactMap { $0.claimRoleId })
        guard claimedIds.count >= 2 else { return [] }
        let source: [Jinx] = (board.edition?.jinxes.isEmpty == false)
            ? board.edition!.jinxes
            : allJinxes
        return source.filter { jinx in
            jinx.roles.filter { claimedIds.contains($0) }.count >= 2
        }
    }

    // Loaded from bundle — no SwiftData dependency
    var activeFabled: [RoleDefinitionModel] {
        board.activeFabledIds.compactMap { id in bundleFabled.first(where: { $0.id == id }) }
    }

    /// Edition characters + all travellers from the global pool.
    /// Travellers are never part of a script JSON but can be assigned to any player.
    var rolesForClaiming: [RoleDefinition] {
        guard let editionChars = board.edition?.characters, !editionChars.isEmpty else {
            return allRoles
        }
        let editionIds = Set(editionChars.map { $0.id })
        let extraTravellers = allRoles.filter { $0.team == .traveller && !editionIds.contains($0.id) }
        return editionChars + extraTravellers
    }

    var body: some View {
        VStack(spacing: 0) {
            // Day selector
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
            .padding(.horizontal)
            .padding(.top, 8)

            // Board canvas – fills remaining space
            ZStack {
                playerGridView()
                    .padding(.vertical)

                // Voting banner overlaid at top of board
                if isVotingPhase {
                    VStack {
                        HStack {
                            Spacer()
                            Label(MSG("board_voting"), systemImage: "flag.pattern.checkered")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.75))
                                .clipShape(Capsule())
                                .onTapGesture { isVotingPhase = false }
                            Spacer()
                        }
                        .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom action & info bar
            bottomBar()
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
                    Button(MSG("fabled_manage_title"), systemImage: "star.circle.fill") {
                        showManageFabled = true
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
        .onDisappear { try? modelContext.save() }
        .task {
            bundleFabled = loadPredefinedRoles().filter { $0.team == .fabled }
        }
        .sheet(isPresented: $showNewGameSetup) {
            NewGameSetupSheet(board: board) { }
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderSheet(board: board, roles: board.edition?.characters ?? allRoles)
        }
        .sheet(isPresented: $showManageFabled) {
            ManageFabledSheet(board: board, allFabled: bundleFabled)
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
                        // Propagate dead state forward to all days after the edited day.
                        // If the player is marked dead on day D, they must still appear
                        // dead on days D+1, D+2, etc. If un-marked, clear future days too.
                        let editedDayIndex = status.dayIndex
                        let isDead = status.dead
                        let deathType = status.deathType
                        for futureStatus in player.statuses where futureStatus.dayIndex > editedDayIndex {
                            futureStatus.dead = isDead
                            futureStatus.deathType = isDead ? deathType : nil
                        }
                        try? modelContext.save()
                        editingPlayer = nil
                    },
                    isMe: player.isMe,
                    totalDays: board.players.first?.statuses.count ?? 1,
                    statusesByDay: player.statuses,
                    currentDayIndex: board.currentDay,
                    roles: rolesForClaiming
                )
            }
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    func bottomBar() -> some View {
        VStack(spacing: 0) {
            // Expandable info panel
            if showInfoPanel {
                VStack(alignment: .center, spacing: 10) {
                    // Player count summary
                    HStack(spacing: 14) {
                        boardStat(value: board.players.count, label: "main-logo-old")
                        boardStat(value: board.config.numTownsfolk, label: "logo_townsfolk")
                        boardStat(value: board.config.numOutsider, label: "logo_outsider")
                        boardStat(value: board.config.numMinions, label: "logo_minion")
                        boardStat(value: board.config.numDemon, label: "logo_demon")
                        if !activeFabled.isEmpty {
                            Spacer()
                        }
                    }

                    // Active fabled
                    if !activeFabled.isEmpty {
                        Divider().overlay(Color.white.opacity(0.2))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(MSG("fabled_in_play"))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.yellow.opacity(0.9))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(activeFabled, id: \.id) { fabled in
                                        fabledChip(fabled)
                                    }
                                }
                            }
                        }
                    }

                    // Active jinxes
                    if !activeJinxes.isEmpty {
                        Divider().overlay(Color.white.opacity(0.2))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(MSG("jinxes_title"))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.orange.opacity(0.9))
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(activeJinxes) { jinx in
                                        jinxRow(jinx)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial.opacity(0.9))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Always-visible action strip
            HStack(spacing: 0) {
                Button(MSG("board_new_day")) { addDay() }
                    .buttonStyle(.borderedProminent)
                    .padding(.leading, 16)

                Spacer()

                if let edition = board.edition {
                    Button(edition.meta.name) { showDetail = true }
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer()

                // Compact badge when panel is hidden
                if !showInfoPanel && (!activeFabled.isEmpty || !activeJinxes.isEmpty) {
                    HStack(spacing: 4) {
                        if !activeFabled.isEmpty {
                            Label("\(activeFabled.count)", systemImage: "star.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.yellow)
                        }
                        if !activeJinxes.isEmpty {
                            Label("\(activeJinxes.count)", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { showInfoPanel.toggle() }
                } label: {
                    Image(systemName: showInfoPanel ? "chevron.down.circle.fill" : "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.leading, 6)
                .padding(.trailing, 16)
            }
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.4))
        }
    }

    @ViewBuilder
    private func fabledChip(_ fabled: RoleDefinitionModel) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
            Text(fabled.nameLocalized())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.yellow.opacity(0.2))
        .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func jinxRow(_ jinx: Jinx) -> some View {
        let roleNames = jinx.roles.compactMap { id in
            allRoles.first(where: { $0.id == id })?.nameLocalized()
        }
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text(roleNames.joined(separator: " + "))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
            }
            Text(jinx.desc)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 17)
        }
    }

    @ViewBuilder
    func boardStat(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Image(label)
                .resizable()
                .frame(width: 50, height: 50)
                .scaledToFit()
            Text("\(value)")
                .font(.title)
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Board canvas

    @ViewBuilder
    func playerGridView() -> some View {
        GeometryReader { geo in
            let orderedPlayers = board.players.sorted { $0.seatNumber < $1.seatNumber }
            let fallbackPositions: [CGPoint] = {
                guard orderedPlayers.contains(where: { $0.posX < 0 }) else { return [] }
                return circlePerimeterPositions(count: orderedPlayers.count, in: geo.size)
            }()

            ZStack {
                // Player tokens
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
                            roles: rolesForClaiming,
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
                        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isDragging)
                        .gesture(
                            DragGesture(minimumDistance: 8)
                                .onChanged { value in
                                    if draggedPlayerIdx != idx {
                                        feedbackGenerator.impactOccurred()
                                        draggedPlayerIdx = idx
                                    }
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    guard draggedPlayerIdx == idx else { return }
                                    let p = orderedPlayers[idx]
                                    let currentPos: CGPoint = p.posX >= 0
                                        ? CGPoint(x: p.posX * geo.size.width, y: p.posY * geo.size.height)
                                        : (idx < fallbackPositions.count ? fallbackPositions[idx]
                                            : CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                                    let newX = min(max(currentPos.x + value.translation.width, 0), geo.size.width)
                                    let newY = min(max(currentPos.y + value.translation.height, 0), geo.size.height)
                                    // Set position and reset drag state atomically — avoids double-offset jump
                                    p.posX = newX / geo.size.width
                                    p.posY = newY / geo.size.height
                                    draggedPlayerIdx = nil
                                    dragOffset = .zero
                                    try? modelContext.save()
                                }
                        )
                    }
                }

                // Reminder tokens (rendered on top of player tokens)
                ForEach(board.reminders) { reminder in
                    let rBase = CGPoint(x: reminder.posX * geo.size.width,
                                       y: reminder.posY * geo.size.height)
                    let isRDragging = draggedReminderId == reminder.id
                    ReminderChip(text: reminder.text, color: reminder.uiColor)
                        .position(rBase + (isRDragging ? reminderDragOffset : .zero))
                        .scaleEffect(isRDragging ? 1.1 : 1.0)
                        .shadow(color: isRDragging ? .black.opacity(0.35) : .clear,
                                radius: isRDragging ? 6 : 0)
                        .zIndex(isRDragging ? 5 : 3)
                        .animation(.spring(response: 0.25, dampingFraction: 0.88), value: isRDragging)
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    if draggedReminderId != reminder.id {
                                        feedbackGenerator.impactOccurred()
                                        draggedReminderId = reminder.id
                                    }
                                    reminderDragOffset = value.translation
                                }
                                .onEnded { value in
                                    guard draggedReminderId == reminder.id else { return }
                                    let newX = min(max(reminder.posX * geo.size.width + value.translation.width, 0), geo.size.width)
                                    let newY = min(max(reminder.posY * geo.size.height + value.translation.height, 0), geo.size.height)
                                    reminder.posX = newX / geo.size.width
                                    reminder.posY = newY / geo.size.height
                                    draggedReminderId = nil
                                    reminderDragOffset = .zero
                                    try? modelContext.save()
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
                initPositionsIfNeeded(geo.size, players: orderedPlayers)
            }
            .onChange(of: geo.size) { _, newSize in
                boardCanvasSize = newSize
            }
        }
        .padding(.horizontal, isRegular ? 80 : 36)
        .padding(.vertical, isRegular ? 60 : 36)
    }

    // MARK: - Helpers

    func initPositionsIfNeeded(_ size: CGSize, players: [Player]) {
        guard size.width > 0, size.height > 0 else { return }
        guard players.contains(where: { $0.posX < 0 }) else { return }
        let positions = circlePerimeterPositions(count: players.count, in: size)
        var changed = false
        for (idx, player) in players.enumerated() where player.posX < 0 {
            guard idx < positions.count else { continue }
            player.posX = positions[idx].x / size.width
            player.posY = positions[idx].y / size.height
            changed = true
        }
        if changed { try? modelContext.save() }
    }

    func circlePerimeterPositions(count: Int, in size: CGSize) -> [CGPoint] {
        guard count > 0 else { return [] }
        let cx = size.width / 2
        let cy = size.height / 2
        let rx = cx * 1.0
        let ry = cy * 1.0
        // Superellipse: 2 = puro óvalo, 4 = squircle, >4 = más rectangular
        let n: CGFloat = 4.0
        let angleStep = 2 * CGFloat.pi / CGFloat(count)
        // Seat 1 empieza a las 12 en punto (−π/2)
        return (0..<count).map { i in
            let t = -CGFloat.pi / 2 + CGFloat(i) * angleStep
            let cosT = cos(t), sinT = sin(t)
            let x = cx + rx * (cosT < 0 ? -1 : 1) * pow(abs(cosT), 2 / n)
            let y = cy + ry * (sinT < 0 ? -1 : 1) * pow(abs(sinT), 2 / n)
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Actions

    func addDay() {
        let newDayIndex = board.players.first?.statuses.count ?? 0
        for player in board.players {
            guard let prev = player.statuses.first(where: { $0.dayIndex == board.currentDay }) else { continue }
            player.statuses.append(PlayerStatus(
                dayIndex: newDayIndex,
                seatNumber: prev.seatNumber,
                voted: false, nominated: false,
                dead: prev.dead, deathType: prev.deathType,
                claim: prev.claim, notes: ""
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
            seatNumber: seatNumber, name: "", isMe: false,
            statuses: (0..<totalDays).map { PlayerStatus(dayIndex: $0) }
        )
        // Place at center so the new token is always visible and not overlapping
        // existing dragged tokens. User can drag it to the desired spot.
        newPlayer.posX = 0.5
        newPlayer.posY = 0.5
        board.players.append(newPlayer)
        try? modelContext.save()
    }

    func clearAllVotes() {
        board.players.forEach { p in p.statuses.forEach { $0.voted = false } }
        try? modelContext.save()
    }

    func clearAllNominations() {
        board.players.forEach { p in p.statuses.forEach { $0.nominated = false } }
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: BoardState.self, configurations: config)
    let context = ModelContext(container)
    let playerCount = 8
    let names = ["Ana", "Bernardo", "Erick", "Fabian", "Carlos", "Dio", "Pedro", "Quike", "Ricardo", "Sergio", "Toni", "Uriel", "Homer", "Zamiel", "Sharar"]
    let players = (1...playerCount).map {
        Player(seatNumber: $0, name: names[$0 - 1],
               statuses: [PlayerStatus(dayIndex: 0, seatNumber: $0)])
    }
    let newConfig = getConfigForPlayerCount(playerCount)
    let configGame = GameConfig(numPlayers: newConfig.numPlayers, numTownsfolk: newConfig.numTownsfolk,
                                numOutsider: newConfig.numOutsider, numMinions: newConfig.numMinions, numDemon: newConfig.numDemon)
    let meta = EditionMeta(id: "test", name: "Trouble Brewing", author: "Me")
    let game = BoardState(suggestedName: "Demo", players: players, currentDay: 0,
                          config: configGame, edition: EditionData(meta: meta, characters: rolesExample))
    context.insert(game)
    return BoardView(board: game).modelContainer(container)
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
]
