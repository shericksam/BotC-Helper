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
    @State private var editingIndex: EditingIndex?
    @State private var isVotingPhase = false
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayerIdx: Int? = nil
    @State private var showResetAlert = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {

            Picker("Día", selection: $board.currentDay) {
                ForEach(Array(board.days.enumerated()), id: \.1.id) { idx, _ in
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
        .sheet(item: $editingIndex) { idx in
            if let player = board.players[safe: idx.value],
               let status = board.days[board.currentDay].playerStatuses[safe: idx.value] {
                PlayerEditor(
                    player: player,
                    status: status,
                    onSave: { _, _ in
                        try? modelContext.save()
                        editingIndex = nil
                    },
                    isMe: player.isMe,
                    totalDays: board.days.count,
                    statusesByDay: board.days.map { $0.playerStatuses[safe: idx.value] ?? PlayerStatus(seatNumber: player.seatNumber) },
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
        let prevStatuses = board.days[board.currentDay].playerStatuses
        let newStatuses = prevStatuses.map { prev in
            PlayerStatus(
                seatNumber: prev.seatNumber,
                voted: false, nominated: false, dead: prev.dead,
                claim: prev.claim, notes: ""
            )
        }
        let newDay = GameDay(index: board.days.count, playerStatuses: newStatuses)
        board.days.append(newDay)
        board.currentDay = board.days.count - 1
        modelContext.insert(newDay)
        try? modelContext.save()
    }

    func addPlayer() {
        let nextSeat = board.players.count + 1
        let player = Player(seatNumber: nextSeat, name: "", claimRoleId: nil, claimManual: "", isMe: false)
        board.players.append(player)
        for day in board.days {
            let status = PlayerStatus(seatNumber: nextSeat)
            day.playerStatuses.append(status)
        }
        modelContext.insert(player)
        try? modelContext.save()
    }

    func clearAllVotes() {
        for day in board.days {
            for status in day.playerStatuses {
                status.voted = false
            }
        }
        try? modelContext.save()
    }

    func clearAllNominations() {
        for day in board.days {
            for status in day.playerStatuses {
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
        }
        let day0: [PlayerStatus] = board.players.map {
            PlayerStatus(seatNumber: $0.seatNumber)
        }
        let newDay = GameDay(index: 0, playerStatuses: day0)
        board.days = [newDay]
        board.currentDay = 0
        board.suggestedName = suggestedFileName(playersCount: board.players.count)
        modelContext.insert(newDay)
        try? modelContext.save()
    }

    @ViewBuilder
    func playerGridView() -> some View {
        GeometryReader { geo in
            let orderedPlayers = board.players.sorted { $0.seatNumber < $1.seatNumber }
            let positions = squarePerimeterPositions(count: board.players.count, in: geo.size)
            ZStack {
                ForEach(Array(orderedPlayers.enumerated()), id: \.1.id) { idx, player in
                    let pos = positions[idx]
                    if let status = board.days[board.currentDay].playerStatuses[safe: idx] {
                        PlayerCircle(
                            player: player,
                            status: status,
                            isMe: player.isMe,
                            roles: board.edition?.characters ?? [],
                            onTap: {
                                if isVotingPhase {
                                    board.days[board.currentDay].playerStatuses[safe: idx]?.voted.toggle()
                                    try? modelContext.save()
                                } else {
                                    editingIndex = EditingIndex(value: idx)

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
                                            // Actualiza orden y seatNumber
//                                            let playerOld = board.players[safe: draggedIdx]
//                                            let oldSeatNumber = playerOld!.seatNumber
//                                            let playerNew = board.players[safe: targetIdx]
//                                            let newSeatNumber = playerNew!.seatNumber
//                                            playerOld!.seatNumber = newSeatNumber
//                                            playerNew!.seatNumber = oldSeatNumber
                                            board.players.swapAt(draggedIdx, targetIdx)

                                            for (i, p) in board.players.enumerated() {
                                                p.seatNumber = i + 1
                                            }
//                                            board.players.sort { $0.seatNumber < $1.seatNumber }
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
    let playerCount = 20
    let players = (1...playerCount).map {
        Player(seatNumber: $0, name: randomString(length: 8), claimManual: "")
    }
    // Día 0: todos vivos, nadie votó
    let statuses = players.map { p in PlayerStatus(seatNumber: p.seatNumber) }
    let day0 = GameDay(index: 0, playerStatuses: statuses)
    let newConfig = getConfigForPlayerCount(playerCount)
    let configGame = GameConfig(numPlayers: newConfig.numPlayers,
                                numTownsfolk: newConfig.numTownsfolk,
                                numOutsider: newConfig.numOutsider,
                                numMinions: newConfig.numMinions,
                                numDemon: newConfig.numDemon)

    let game = BoardState(
        suggestedName: "DemoJuego",
        players: players,
        days: [day0],
        currentDay: 0,
        config: configGame
    )
    context.insert(game)
    return BoardView(board: game)
        .modelContainer(container)
}

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}
