//
//  FriendsListView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Friend.name) var friends: [Friend]

    @State private var newName = ""
    @State private var showingAddField = false
    @FocusState private var isAddFieldFocused: Bool

    var body: some View {
        NavigationView {
            List {
                if showingAddField {
                    HStack {
                        TextField(MSG("friends_name_placeholder"), text: $newName)
                            .focused($isAddFieldFocused)
                            .onSubmit { addFriend() }
                        Button(action: addFriend) {
                            Text(MSG("friends_add_confirm"))
                                .bold()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                ForEach(friends) { friend in
                    Text(friend.name)
                }
                .onDelete(perform: deleteFriends)
            }
            .navigationTitle(MSG("friends_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddField = true
                        isAddFieldFocused = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(MSG("close")) { dismiss() }
                }
            }
            .overlay {
                if friends.isEmpty && !showingAddField {
                    ContentUnavailableView(
                        MSG("friends_empty_title"),
                        systemImage: "person.2",
                        description: Text(MSG("friends_empty_description"))
                    )
                }
            }
        }
    }

    private func addFriend() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let friend = Friend(name: trimmed)
        modelContext.insert(friend)
        try? modelContext.save()
        newName = ""
        showingAddField = false
    }

    private func deleteFriends(at offsets: IndexSet) {
        for idx in offsets {
            modelContext.delete(friends[idx])
        }
        try? modelContext.save()
    }
}

#Preview {
    FriendsListView()
}
