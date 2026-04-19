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
    @State private var showingFriendsList = false

    @State private var boardState: BoardState? = nil
    @State private var didPreload = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 32) {
                    Spacer()
                    VStack {
                        Image("title")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                        Image("main-logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(Circle())
                    }
                    .padding(.top, 32)
                    Spacer()
                    if didPreload {
                        VStack(spacing: 18) {
                            Button(action: { showingNewGameSheet = true }) {
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

                            Button(action: { showingEditionsSheet = true }) {
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

                            Button(action: { showingLoadView = true }) {
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

                            Button(action: { showingFriendsList = true }) {
                                Label(MSG("friends_title"), systemImage: "person.2.fill")
                                    .font(.title3)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            .sheet(isPresented: $showingFriendsList) {
                                FriendsListView()
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.7), value: didPreload)
                    } else {
                        VStack(spacing: 24) {
                            ProgressView(MSG("loading_resources"))
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                                .scaleEffect(1.5)
                                .padding(.top, 36)
                        }
                        .transition(.opacity)
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
                    Spacer()
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
        .task {
            await PreloadContent()
                .preloadDefaultEditionsAndRolesIfNeeded(modelContext: modelContext)
            withAnimation(.easeOut(duration: 0.6)) {
                didPreload = true
            }
        }
    }
}
#Preview {
    MainView()
}
