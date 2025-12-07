//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct EditingIndex: Identifiable {
    var id: Int { value }
    var value: Int
}

struct BoardView: View {
    @State var board: BoardState
    @State private var selectedPlayer: Player?
    @State private var selectedStatus: PlayerStatusPerDay?
    @State private var editingIndex: EditingIndex?
    @State private var isVotingPhase = false
    @State private var showDetail = false

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
                // Selector de Día
                Picker("Día", selection: $board.currentDay) {
                    ForEach(0..<board.days.count, id: \.self) { i in
                        Text("Día \(i)").tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .padding(.top, 25)

                Spacer()
                ZStack {
                    // Distribución de Jugadores en círculo
                    GeometryReader { geo in
                        let positions = squarePerimeterPositions(count: board.players.count, in: geo.size)
                        ZStack {
                            ForEach(Array(board.players.indices), id: \.self) { idx in
                                let pos = positions[idx]
                                PlayerCircle(
                                    player: board.players[idx],
                                    status: board.days[board.currentDay][idx],
                                    isMe: board.players[idx].isMe,
                                    roles: board.edition?.characters ?? []
                                ) {
                                    if isVotingPhase {
                                        board.days[board.currentDay][idx].voted.toggle()
                                    } else {
                                        editingIndex = EditingIndex(value: idx)
                                    }
                                }
                                .position(pos + (draggedPlayer == idx ? dragOffset : .zero))
                                .zIndex(draggedPlayer == idx ? 1 : 0)
                                .gesture(
                                    LongPressGesture(minimumDuration: 0.2)
                                        .onEnded { _ in
                                            draggedPlayer = idx
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
                                        .onEnded { value in
                                            if let draggedIdx = draggedPlayer {
                                                // Detectar a qué círculo se soltó encima:
                                                let newPosition = positions[draggedIdx] + dragOffset
                                                if let targetIdx = positions.enumerated().min(by: {
                                                    distance($0.element, newPosition) < distance($1.element, newPosition)
                                                })?.offset,
                                                targetIdx != draggedIdx {
                                                    board.players.swapAt(draggedIdx, targetIdx)
                                                    // Actualiza seatNumber si es necesario
                                                    for (i, _) in board.players.enumerated() {
                                                        board.players[i].seatNumber = i+1
                                                    }
                                                }
                                                // Regresa a su lugar
                                                draggedPlayer = nil
                                                dragOffset = .zero
                                            }
                                        }
                                )
                            }
                        }
                    }
                    .frame(height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 1.4)
                    .aspectRatio(1, contentMode: .fit)
                    .padding()

                    // Configuración en el centro
                    VStack {
                        if isVotingPhase {
                            VStack {
                                Image(systemName: "flag.pattern.checkered")
                                Text("Votando...")
                            }
                        }
                        Button(action: {
                            // Copia profunda manual: el status debe ser un struct totalmente independiente
                            let prevStatuses = board.days[board.currentDay]
                            // ¡Importante! No solo .map { $0 }, debes crear nuevos structs para evitar referencias compartidas.
                            let copied = prevStatuses.map { prevStatus in
                                PlayerStatusPerDay(
                                    seatNumber: prevStatus.seatNumber,
                                    voted: false,
                                    nominated: false,
                                    dead: prevStatus.dead,   // Mantén solo el estado de muerto
                                    claim: prevStatus.claim,
                                    notes: ""                // puedes dejar vacío o copiar si quieres
                                )
                            }
                            // Ahora haz el cambio en el board completo:
                            var newBoard = board
                            newBoard.days.append(copied)
                            newBoard.currentDay = newBoard.days.count - 1
                            board = newBoard
                            saveBoardState(board)
                        }) {
                            Label("Nuevo Día", systemImage: "sun.max")
                        }
                        .buttonStyle(.borderedProminent)
                        if let edition = board.edition {
                            Button(edition.meta.name) {
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
                        
                        NavigationLink(destination: GPTAssistantView(board: board)) {
                            Label("Análisis AI", systemImage: "bolt.circle.fill")
                        }
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .padding()
                }
                .padding(30)
                .padding(.bottom, 30)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Guardar partida", systemImage: "square.and.arrow.down") {
                        saveBoardState(board)
                    }
                    Button("Agregar jugador", systemImage: "person.crop.circle.badge.plus") {
                        addPlayer()
                    }

                    Button(isVotingPhase ? "Terminar votación" : "Iniciar votación",
                           systemImage: isVotingPhase ? "flag.filled.and.flag.crossed" : "flag.pattern.checkered") {
                        isVotingPhase.toggle()
                        // Si terminas votación, podrías limpiar o validar algo si quieres
                    }
                    .foregroundColor(isVotingPhase ? .red : .blue)

                    Button("Limpiar todos los votos", systemImage: "checkmark.circle") {
                        clearAllVotes()
                    }
                    Button("Limpiar todas las acusaciones", systemImage: "exclamationmark.bubble") {
                        clearAllNominations()
                    }
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
                    player: $board.players[idx],
                    status: status,
                    onSave: { updated, notes in
                        board.days[board.currentDay][idx] = updated
                        board.players[idx].personalNotes = notes
                        saveBoardState(board)
                        // cierra el sheet
                        editingIndex = nil
                    },
                    isMe: isMe,
                    totalDays: board.days.count,
                    statusesByDay: statusHistorial,
                    currentDayIndex: board.currentDay,
                    roles: board.edition?.characters ?? []
                )
            } else {
                Text("No hay jugador para editar")
            }
        }
    }
    // suma de puntos
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
    func addPlayer() {
        let nextSeat = board.players.count + 1
        board.players.append(Player(seatNumber: nextSeat, name: "", claimManual: "", isMe: false, personalNotes: [:]))
        // Añade estado a todos los días existentes para este jugador:
        for i in 0..<board.days.count {
            board.days[i].append(PlayerStatusPerDay(
                seatNumber: nextSeat, voted: false, nominated: false, dead: false, claim: "", notes: ""
            ))
        }
    }
    func clearAllVotes() {
        for day in 0..<board.days.count {
            for idx in 0..<board.days[day].count {
                board.days[day][idx].voted = false
            }
        }
    }
    func clearAllNominations() {
        for day in 0..<board.days.count {
            for idx in 0..<board.days[day].count {
                board.days[day][idx].nominated = false
            }
        }
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
        // Calcula cuántos van por lado
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
    BoardView(board: BoardState.Mock.example)
}
