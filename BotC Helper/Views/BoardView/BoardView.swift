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
    @Bindable var board: BoardState
    @State private var editingPlayer: Player?
    @State private var isVotingPhase = false
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayerIdx: Int? = nil
    @State private var showResetAlert = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {

            Picker("Día", selection: $board.currentDay) {
                ForEach(0..<board.totalDays, id: \.self) { idx in
                    Text("Día \(idx)").tag(idx)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 25)

            Spacer()

            ZStack {
                playerGridView()

                // --- Configuración central ---
                VStack {
                    if isVotingPhase {
                        VStack {
                            Image(systemName: "flag.pattern.checkered")
                            Text("Votando...")
                        }
                    }
                    Button("Nuevo Día") { addDay() }
                        .buttonStyle(.borderedProminent)
                        .padding(.vertical, 5)
                    if let edition = board.edition {
                        Button(edition.meta.name) {
                            showDetail.toggle()
                        }
                        .font(.title2)
                    }
                    Text("Jugadores: \(board.players.count)").font(.title3).bold()
                    Text("Poblado: \(board.config.numTownsfolk)").font(.body)
                    Text("Forasteros: \(board.config.numOutsider)").font(.body)
                    Text("Esbirros: \(board.config.numMinions)").font(.body)
                    Text("Demonio: \(board.config.numDemon)").font(.body)
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
                    Button("Guardar partida", systemImage: "square.and.arrow.down") {
                        try? modelContext.save()
                    }
                    Button("Agregar jugador", systemImage: "person.crop.circle.badge.plus") {
                        addPlayer()
                    }
                    Button(isVotingPhase ? "Terminar votación" : "Iniciar votación",
                           systemImage: isVotingPhase ? "flag.filled.and.flag.crossed" : "flag.pattern.checkered") {
                        isVotingPhase.toggle()
                    }
                    Button("Limpiar todos los votos", systemImage: "checkmark.circle") { clearAllVotes() }
                    Button("Limpiar todas las acusaciones", systemImage: "exclamationmark.bubble") { clearAllNominations() }
                    Button("Nueva partida", systemImage: "arrow.clockwise") { showResetAlert = true }
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
        .alert("¿Borrar progreso?", isPresented: $showResetAlert) {
            Button("Sí, limpiar todo", role: .destructive) {
                resetBoardForNewGame()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esto deja las posiciones y nombres, pero borra todos los claims, notas y progreso actual. ¿Seguro que quieres reiniciar la partida?")
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
                Text("No hay jugador para editar")
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
                                            board.players.swapAt(draggedIdx, targetIdx)
                                            let oldSeat = board.players[targetIdx].seatNumber
                                            board.players[targetIdx].seatNumber = board.players[draggedIdx].seatNumber
                                            board.players[draggedIdx].seatNumber = oldSeat

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
        .padding(.horizontal, 40)
        .padding(.vertical, 50)
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
    let playerCount = 12
    let names = ["Ana", "Bernardo", "Erick", "Fabian", "Carlos", "Dio", "Pedro", "Quike", "Ricardo", "Sergio", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera", "Ricardo", "Sandro", "Toni", "Uriel", "Ximena", "Yair", "Zamiel", "Manuel", "Oscar", "Nuckle", "Omar", "Pithuo", "Raúl", "Quimera"]
    let players = (1...playerCount).map {
        Player(seatNumber: $0, name: names[$0], claimRoleId: rolesExample[$0].name, statuses: [
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
        suggestedName: "DemoJuego",
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
    RoleDefinition(id: "grandmother", name: "grandmother"),
    RoleDefinition(id: "acrobat", name: "acrobat"),
    RoleDefinition(id: "fortuneteller", name: "fortuneteller"),
    RoleDefinition(id: "steward", name: "steward"),
    RoleDefinition(id: "balloonist", name: "balloonist"),
    RoleDefinition(id: "mayor", name: "mayor"),
    RoleDefinition(id: "alchemist", name: "alchemist"),
    RoleDefinition(id: "alsaahir", name: "alsaahir"),
    RoleDefinition(id: "amnesiac", name: "amnesiac"),
    RoleDefinition(id: "artist", name: "artist"),
    RoleDefinition(id: "atheist", name: "atheist"),
    RoleDefinition(id: "librarian", name: "librarian"),
    RoleDefinition(id: "fool", name: "fool"),
    RoleDefinition(id: "knight", name: "knight"),
    RoleDefinition(id: "cannibal", name: "cannibal"),
    RoleDefinition(id: "huntsman", name: "huntsman"),
    RoleDefinition(id: "bountyhunter", name: "bountyhunter"),
    RoleDefinition(id: "gossip", name: "gossip"),
    RoleDefinition(id: "chef", name: "chef"),
    RoleDefinition(id: "courtier", name: "courtier"),
    RoleDefinition(id: "seamstress", name: "seamstress"),
    RoleDefinition(id: "cultleader", name: "cultleader"),
    RoleDefinition(id: "poppygrower", name: "poppygrower"),
    RoleDefinition(id: "empath", name: "empath"),
    RoleDefinition(id: "snakecharmer", name: "snakecharmer"),
    RoleDefinition(id: "undertaker", name: "undertaker"),
    RoleDefinition(id: "savant", name: "savant"),
    RoleDefinition(id: "exorcist", name: "exorcist"),
    RoleDefinition(id: "slayer", name: "slayer"),
    RoleDefinition(id: "philosopher", name: "philosopher"),
    RoleDefinition(id: "general", name: "general"),
    RoleDefinition(id: "farmer", name: "farmer"),
    RoleDefinition(id: "ravenkeeper", name: "ravenkeeper"),
    RoleDefinition(id: "pixie", name: "pixie"),
    RoleDefinition(id: "engineer", name: "engineer"),
    RoleDefinition(id: "investigator", name: "investigator"),
    RoleDefinition(id: "washerwoman", name: "washerwoman"),
    RoleDefinition(id: "lycanthrope", name: "lycanthrope"),
    RoleDefinition(id: "banshee", name: "banshee"),
    RoleDefinition(id: "gambler", name: "gambler"),
    RoleDefinition(id: "magician", name: "magician"),
    RoleDefinition(id: "juggler", name: "juggler"),
    RoleDefinition(id: "sailor", name: "sailor"),
    RoleDefinition(id: "mathematician", name: "mathematician"),
    RoleDefinition(id: "monk", name: "monk"),
    RoleDefinition(id: "flowergirl", name: "flowergirl"),
    RoleDefinition(id: "choirboy", name: "choirboy"),
    RoleDefinition(id: "noble", name: "noble"),
    RoleDefinition(id: "oracle", name: "oracle"),
    RoleDefinition(id: "pacifist", name: "pacifist"),
    RoleDefinition(id: "fisherman", name: "fisherman"),
    RoleDefinition(id: "innkeeper", name: "innkeeper"),
    RoleDefinition(id: "predicador", name: "predicador"),
    RoleDefinition(id: "towncrier", name: "towncrier"),
    RoleDefinition(id: "princess", name: "princess"),
    RoleDefinition(id: "professor", name: "professor"),
    RoleDefinition(id: "clockmaker", name: "clockmaker"),
    RoleDefinition(id: "king", name: "king"),
    RoleDefinition(id: "sage", name: "sage"),
    RoleDefinition(id: "highpriestess", name: "highpriestess"),
    RoleDefinition(id: "tealady", name: "tealady"),
    RoleDefinition(id: "shugenja", name: "shugenja"),
    RoleDefinition(id: "chambermaid", name: "chambermaid"),
    RoleDefinition(id: "soldier", name: "soldier"),
    RoleDefinition(id: "dreamer", name: "dreamer")
]
