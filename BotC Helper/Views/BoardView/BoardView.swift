//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct EditingIndex: Identifiable {
    var id: Int { value }
    var value: Int
}

struct BoardView: View {
    @State var board: BoardState
    @State private var selectedPlayer: Player?
    @State private var selectedStatus: PlayerStatusPerDay?
    @State private var editingIndex: EditingIndex?
    @State private var showingSaveSheet = false
    @State private var isVotingPhase = false

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

                Spacer()
                ZStack {
                    // Distribución de Jugadores en círculo
                    GeometryReader { geo in
                        let positions = squarePerimeterPositions(count: board.players.count, in: geo.size)
                        ZStack {
                            ForEach(Array(board.players.indices), id: \.self) { idx in
//                                let pos =
                                PlayerCircle(
                                    player: board.players[idx],
                                    status: board.days[board.currentDay][idx],
                                    isMe: board.players[idx].isMe
                                ) {
                                    if isVotingPhase {
                                        board.days[board.currentDay][idx].voted.toggle()
                                    } else {
                                        editingIndex = EditingIndex(value: idx)
                                    }
                                }
                                    .position(positions[idx])
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
                        }) {
                            Label("Nuevo Día", systemImage: "sun.max")
                        }
                        .buttonStyle(.borderedProminent)

                        Text("Jugadores: \(board.players.count)")
                            .font(.title2)
                            .bold()
                        Text("Poblado: \(board.config.numTownsfolk)")
                            .font(.body)
                        Text("Forasteros: \(board.config.numOutsider)")
                            .font(.body)
                        Text("Esbirros: \(board.config.numMinions)")
                            .font(.body)
                        Text("Demonio: \(board.config.numDemon)")
                            .font(.body)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white)
                    .padding()
                }
                .padding(30)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveGameSheet(
                isPresented: $showingSaveSheet,
                suggestedName: suggestedFileName(for: board)
            ) { name in
                saveBoardState(board, fileName: name)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Guardar partida", systemImage: "square.and.arrow.down") {
                        showingSaveSheet = true
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
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
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
                        // cierra el sheet
                        editingIndex = nil
                    },
                    isMe: isMe,
                    totalDays: board.days.count,
                    statusesByDay: statusHistorial,
                    currentDayIndex: board.currentDay
                )
            } else {
                Text("No hay jugador para editar")
            }
        }
    }

    func addPlayer() {
        let nextSeat = board.players.count + 1
        board.players.append(Player(seatNumber: nextSeat, name: "", claim: "", isMe: false, personalNotes: [:]))
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

#Preview {
    BoardView(board: BoardState.Mock.example)
}
