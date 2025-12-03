//
//  BoardView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct BoardView: View {
    @State var board: BoardState
    @State private var selectedPlayer: Player?
    @State private var selectedStatus: PlayerStatusPerDay?
    @State private var editingIndex: Int?
    @State private var showingSaveSheet = false

    var body: some View {
        ZStack {
            Image("background-side")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)
            VStack {

                HStack {
                    // Botón para agregar nuevo día
//                    if board.currentDay > 0 {
//                        Button(action: {
//                            board.currentDay -= 1
//                        }) {
//                            Label("Día anterior", systemImage: "arrow.left")
//                        }
//                        .foregroundStyle(Color.white)
//                    }
//                    Spacer()
                    Button(action: {
                        // Añadir nuevo día, copiando el estado del día actual
                        //                        Task {
                        let prevStatuses = board.days[board.currentDay]
                        let copied = prevStatuses.map { prevStatus in
                            var newStatus = prevStatus
                            newStatus.voted = false
                            newStatus.nominated = false
                            return newStatus
                        } // Clona el arreglo
                        //                            Task { @MainActor in
                        board.days.append(copied)
                        board.currentDay = board.days.count - 1 // pasa al nuevo día
                        //                            }
                        //                        }
                    }) {
                        Label("Nuevo Día", systemImage: "plus.circle")
                    }
                    .foregroundStyle(Color.white)
                }
                .padding()
                .padding(.top, 20)
                // Selector de Día
                Picker("Día", selection: $board.currentDay) {
                    ForEach(0..<board.days.count, id: \.self) { i in
                        Text("D \(i)").tag(i)
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
                            ForEach(board.players.indices, id: \.self) { idx in
                                let pos = positions[idx]
                                PlayerCircle(
                                    player: board.players[idx],
                                    status: board.days[board.currentDay][idx],
                                    isMe: board.players[idx].isMe
                                ) { editingIndex = idx }
                                    .position(pos)
                            }
                        }
                    }
                    .frame(height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 1.4)
                    .aspectRatio(1, contentMode: .fit)
                    .padding()

                    // Configuración en el centro
                    VStack {
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
        .navigationTitle("Tablero")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Guardar") {
                    showingSaveSheet = true
                }
            }
        }
        // Sheet para editar jugador
        .sheet(isPresented: .constant(editingIndex != nil), onDismiss: {
            editingIndex = nil
        }) {
            if let idx = editingIndex, idx < board.players.count, idx < board.days[board.currentDay].count {
                // copia de status activo
                let isMe = board.players[idx].isMe
                let status = board.days[board.currentDay][idx]
                let statusHistorial = board.days.map { $0[idx] }
                PlayerEditor(
                    player: $board.players[idx],
                    status: status,
                    onSave: { updated, notes in
                        board.days[board.currentDay][idx] = updated
                        board.players[idx].personalNotes = notes
                    },
                    isMe: isMe,
                    totalDays: board.days.count,
                    statusesByDay: statusHistorial,
                    currentDayIndex: board.currentDay
                )
            } else {
                // Fallback defensivo si el índice no es válido
                Text("No hay jugador para editar")
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
