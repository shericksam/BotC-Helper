//
//  MainView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 02/12/25.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) var modelContext
    @State private var showingNewGameSheet = false
    @State private var showingEditionsSheet = false
    @State private var isShowingGameBoard: Bool = false

    @State private var showingLoadView = false

    @State private var boardState: BoardState? = nil // el nuevo tablero
    @State private var didPreload = false
    var body: some View {
        Group {
            if didPreload {
                bodyLoaded // O lo que sea tu vista principal, aquí aparece el query
            } else {
                ProgressView("Cargando recursos...")
            }
        }

        .task {
            await PreloadContent().preloadDefaultEditionsAndRolesIfNeeded(modelContext: modelContext)
            didPreload = true
        }
    }

    var bodyLoaded: some View {
        NavigationStack {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 32) {
                    VStack {
                        Image("title")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)

                        Image("main-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                    .padding(.top, 32)

                    Spacer()
                    VStack(spacing: 12) {

                        Button(action: {
                            showingNewGameSheet.toggle()
                        }) {
                            HStack {
                                Label("Nueva Partida", systemImage: "plus.circle.fill")
                                    .font(.title2)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .sheet(isPresented: $showingNewGameSheet) {
                            NewGameSheet { config in
                                boardState = config
                                isShowingGameBoard = true
                                showingNewGameSheet = false
                            }
                        }

                        Button(action: {
                            showingEditionsSheet.toggle()
                        }) {
                            Label("Ver/Editar Ediciones", systemImage: "books.vertical.fill")
                                .font(.title2)
                                .padding()

                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .sheet(isPresented: $showingEditionsSheet) {
                            EditionsSheet()
                        }

                        Button(action: {
                            showingLoadView.toggle()
                        }) {
                            Label("Partidas Anteriores", systemImage: "clock.fill")
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                        }
                        .sheet(isPresented: $showingLoadView) {
//                            LoadGameListView { loadedBoard in
//                                boardState = loadedBoard
//                                isShowingGameBoard = true
//                                showingLoadView = false
//                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $isShowingGameBoard) {
                if let board = boardState {
//                    BoardView(board: board)
                } else {
                    Text("No hay tablero disponible")
                }
            }
        }
    }
}

#Preview {
    MainView()
}
