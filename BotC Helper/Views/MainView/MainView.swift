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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Logo header
                    VStack(spacing: 8) {
                        Text("BotC Notes")
                            .font(.custom("UnifrakturMaguntia", size: 65))
                            .foregroundColor(.accentColor)
                            .shadow(color: .black.opacity(0.65), radius: 6, x: 0, y: 3)


                            Image("main-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)

                        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .padding(.top, 36)
                    .padding(.bottom, 24)

                    // Main content
                    if didPreload {
                        // 2×2 action grid
                        LazyVGrid(columns: columns, spacing: 14) {
                            menuCard(
                                title: MSG("new_game_label"),
                                icon: "plus.circle.fill",
                                color: Color(red: 0.7, green: 0.1, blue: 0.1)
                            ) { showingNewGameSheet = true }

                            menuCard(
                                title: MSG("edit_editions_label"),
                                icon: "books.vertical.fill",
                                color: Color(red: 0.55, green: 0.35, blue: 0.1)
                            ) { showingEditionsSheet = true }

                            menuCard(
                                title: MSG("previous_games_label"),
                                icon: "clock.arrow.circlepath",
                                color: Color(red: 0.15, green: 0.25, blue: 0.55)
                            ) { showingLoadView = true }

                            menuCard(
                                title: MSG("friends_title"),
                                icon: "person.2.fill",
                                color: Color(red: 0.35, green: 0.1, blue: 0.5)
                            ) { showingFriendsList = true }
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeOut(duration: 0.55), value: didPreload)

                        Spacer(minLength: 16)

                        // Disclaimer
                        Text(MSG("app_disclaimer"))
                            .font(.system(size: 10))
                            .foregroundColor(.black.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 10)

                        // About button
                        Button {
                            showingAbout = true
                        } label: {
                            Label(MSG("main_more_info"), systemImage: "info.circle")
                                .font(.footnote.weight(.medium))
                                .foregroundColor(.black.opacity(0.75))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 24)

                    } else {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView(MSG("loading_resources"))
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.4)
                                .foregroundColor(.white)
                        }
                        .transition(.opacity)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            )
            // Sheets
            .sheet(isPresented: $showingNewGameSheet) {
                NewGameSheet { config in
                    boardState = config
                    isShowingGameBoard = true
                    showingNewGameSheet = false
                }
            }
            .sheet(isPresented: $showingEditionsSheet) { EditionsSheet() }
            .sheet(isPresented: $showingLoadView) {
                LoadGameListView { loadedBoard in
                    boardState = loadedBoard
                    isShowingGameBoard = true
                    showingLoadView = false
                }
            }
            .sheet(isPresented: $showingFriendsList) { FriendsListView() }
            .sheet(isPresented: $showingAbout) { AboutAppView() }
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
            withAnimation(.easeOut(duration: 0.6)) { didPreload = true }
        }
    }

    @ViewBuilder
    private func menuCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.25))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: color.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainView()
}
