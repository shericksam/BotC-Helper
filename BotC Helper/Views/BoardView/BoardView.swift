//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct BoardView: View {
    @Bindable var board: BoardState
    @State private var editingIndex: EditingIndex?
    @State private var isVotingPhase = false
    @State private var showDetail = false
    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayerIdx: Int? = nil
    @Environment(\.modelContext) private var modelContext

    @State private var dragOffset: CGSize = .zero
    @State private var draggedPlayer: Int? = nil  // idx del jugador arrastrado
    @State private var showResetAlert = false

    var body: some View {
        ZStack {
            Image("background-side")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Picker("Día", selection: $board.currentDay) {
                    ForEach(Array(board.days.enumerated()), id: \.1.id) { i, _ in
                        Text("Día \(i)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, 20)

                Spacer()

                GeometryReader { geo in
                    let positions = squarePerimeterPositions(count: board.players.count, in: geo.size)
                    ZStack {
                        ForEach(Array(board.players.enumerated()), id: \.1.id) { idx, player in
                            let pos = positions[idx]
                            let status = board.days[safe: board.currentDay]?.playerStatuses[safe: idx] ?? .init(seatNumber: player.seatNumber)
                            PlayerCircle(player: player,
                                         status: status,
                                         isMe: player.isMe,
                                         roles: board.edition?.characters ?? [],
                                         onTap: {
                                if isVotingPhase {
                                    if let status = board.days[board.currentDay].playerStatuses[safe: idx] {
                                        status.voted.toggle()
                                        try? modelContext.save()
                                    }
                                } else {
                                    editingIndex = EditingIndex(value: idx)
                                }
                            })
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
                                        default: break
                                        }
                                    }
                                    .onEnded { _ in
                                        if let draggedIdx = draggedPlayerIdx {
                                            let newPosition = positions[draggedIdx] + dragOffset
                                            if let targetIdx = positions.enumerated().min(by: {
                                                distance($0.element, newPosition) < distance($1.element, newPosition)
                                            })?.offset, targetIdx != draggedIdx {
                                                board.players.swapAt(draggedIdx, targetIdx)
                                                for (i, p) in board.players.enumerated() {
                                                    p.seatNumber = i + 1
                                                }
                                                try? modelContext.save()
                                            }
                                            draggedPlayerIdx = nil
                                            dragOffset = .zero
                                        }
                                    }
                            )
                        }

                        centerView()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white)
                            .padding()
                    }

                }
                .frame(height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 1.5)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)

            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Guardar partida", systemImage: "square.and.arrow.down") { try? modelContext.save() }
                    Button("Agregar jugador", systemImage: "person.crop.circle.badge.plus") { addPlayer() }
                    Button(isVotingPhase ? "Terminar votación" : "Iniciar votación",
                           systemImage: isVotingPhase ? "flag.filled.and.flag.crossed" : "flag.pattern.checkered") {
                        isVotingPhase.toggle()
                    }
                    Button("Limpiar todos los votos", systemImage: "checkmark.circle") { clearAllVotes() }
                    Button("Limpiar todas las acusaciones", systemImage: "exclamationmark.bubble") { clearAllNominations() }
                    // 🚀 ¡Nuevo botón!
                    Button("Nueva partida", systemImage: "arrow.clockwise") {
                        showResetAlert = true
                    }
                    .tint(.red)

                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(item: $editingIndex) { idx in
            if let player = board.players[safe: idx.value],
               let status = board.days[board.currentDay].playerStatuses[safe: idx.value] {
        .onDisappear {
            saveBoardState(board)
        }
        .alert("¿Borrar progreso?", isPresented: $showResetAlert) {
            Button("Sí, limpiar todo", role: .destructive) {
                resetBoardForNewGame()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esto deja las posiciones y nombres, pero borra todos los claims, notas y progreso actual. ¿Seguro que quieres reiniciar la partida?")
        }
        .navigationDestination(isPresented: $showDetail) {
            if let data = board.edition {
                EditionDetailView(editionMeta: data)
            } else {
                EmptyView()
            }
        }
        .sheet(item: $editingIndex) { item in
            let idx = item.value
            if idx < board.players.count {
                let isMe = board.players[idx].isMe
                let status = board.days[board.currentDay][idx]
                let statusHistorial = board.days.map { $0[idx] }
                PlayerEditor(
                    player: player,
                    status: status,
                    // ...otros datos...
                    onSave: { _, _ in
                        try? modelContext.save()
                        editingIndex = nil
                    }
                )
            } else {
                Text("No hay jugador para editar")
            }
        }
    }

    // ==================== FUNCIONES ====================

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

    // suma de puntos
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
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

    // etc...

    // Utils
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }

    func resetBoardForNewGame() {
        // Limpia solo lo mutable: roles, claims, notas, estados
        var newPlayers: [Player] = []
        for p in board.players {
            var newPlayer = p
            newPlayer.claimRoleId = nil
            newPlayer.claimManual = ""
            newPlayer.personalNotes = [:]
            // Mantén nombre y seatNumber y isMe
            newPlayers.append(newPlayer)
        }
        // Crea días nuevos: 1 solo, todos vivos (asumiendo PlayerStatusPerDay básico)
        let day0: [PlayerStatusPerDay] = newPlayers.map {
            PlayerStatusPerDay(seatNumber: $0.seatNumber)
        }
        board.players = newPlayers
        board.days = [day0]
        board.currentDay = 0
        board.suggestedName = suggestedFileName(playersCount: board.players.count)
        board.config = getConfigForPlayerCount(board.players.count)
        // Listo para nuevo juego, pero conserva nombres, asientos e “isMe”
        saveBoardState(board)
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

    @ViewBuilder
    func centerView() -> some View {
        VStack {
            if isVotingPhase {
                VStack {
                    Image(systemName: "flag.pattern.checkered")
                    Text("Votando...")
                }
            }
            Button(action: addDay) {
                Label("Nuevo Día", systemImage: "sun.max")
            }
            .buttonStyle(.borderedProminent)
            if let editionName = board.edition?.meta?.name {
                Button(editionName) {
                    showDetail.toggle()
                }
                .font(.title2)
                .bold()
            }
            Text("Jugadores: \(board.players.count)")
                .font(.title3)
                .bold()
            Text("Poblado: \(board.config.numTownsfolk)")
                .font(.body)
            Text("Forasteros: \(board.config.numOutsider)")
                .font(.body)
            Text("Esbirros: \(board.config.numMinions)")
                .font(.body)
            Text("Demonio: \(board.config.numDemon)")
                .font(.body)

//            NavigationLink(destination: GPTAssistantView(board: board)) {
//                Label("Análisis AI", systemImage: "bolt.circle.fill")
//            }
        }
    }
}

// Safe subscript index
extension Array {
    subscript(safe idx: Int) -> Element? { (startIndex..<endIndex).contains(idx) ? self[idx] : nil }
}

struct PlayerDropDelegate: DropDelegate {
    let fromPlayer: Player?
    let toPlayer: Player
    @Binding var board: BoardState

    func performDrop(info: DropInfo) -> Bool {
        guard let from = fromPlayer, from.id != toPlayer.id else { return false }
        if let idxFrom = board.players.firstIndex(where: { $0.id == from.id }),
           let idxTo = board.players.firstIndex(where: { $0.id == toPlayer.id }) {
            // Intercambia los jugadores (recuerda swap seatNumber!)
            board.players.swapAt(idxFrom, idxTo)

            // Mantén seatNumber actualizado si es necesario
            for (i, _) in board.players.enumerated() {
                board.players[i].seatNumber = i+1
            }
        }
        return true
    }
}

extension CGPoint {
    static func + (a: CGPoint, b: CGSize) -> CGPoint {
        CGPoint(x: a.x + b.width, y: a.y + b.height)
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
        Player(seatNumber: $0, name: "", claimManual: "")
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
