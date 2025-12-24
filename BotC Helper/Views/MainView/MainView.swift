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
    @State private var showingAbout: Bool = false

    @State private var showingLoadView = false

    @State private var boardState: BoardState? = nil
    @State private var didPreload = false
    
    var body: some View {
        Group {
            if didPreload {
                bodyLoaded
            } else {
                ProgressView(NSLocalizedString("loading_resources", comment: ""))
            }
        }

        .task {
            await PreloadContent()
                .preloadDefaultEditionsAndRolesIfNeeded(modelContext: modelContext)
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
                                Label(MSG("new_game_label"), systemImage: "plus.circle.fill")
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
                            Label(MSG("edit_editions_label"), systemImage: "books.vertical.fill")
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
                            Label(MSG("previous_games_label"), systemImage: "clock.fill")
                                .font(.title3)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                        }
                        .sheet(isPresented: $showingLoadView) {
                            LoadGameListView { loadedBoard in
                                boardState = loadedBoard
                                isShowingGameBoard = true
                                showingLoadView = false
                            }
                        }
                    }
                    Spacer()
                    Button {
                        showingAbout = true
                    } label: {
                        Label(MSG("main_more_info"), systemImage: "info.circle")
                            .font(.title3)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(12)
                    }
                    .sheet(isPresented: $showingAbout) {
                        AboutAppView()
                    }
                }
                .padding()
            }
            .navigationDestination(isPresented: $isShowingGameBoard) {
                if let board = boardState {
                    BoardView(board: board)
                } else {
                    Text(MSG("no_board_available"))
                }
            }
        }
    }
}

#Preview {
    MainView()
}
