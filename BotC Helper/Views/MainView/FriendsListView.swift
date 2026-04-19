//
//  FriendsListView.swift
//  BotC Helper
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
    @State private var editingFriend: Friend? = nil

    var body: some View {
        NavigationView {
            List {
                if showingAddField {
                    HStack {
                        TextField(MSG("friends_name_placeholder"), text: $newName)
                            .focused($isAddFieldFocused)
                            .onSubmit { addFriend() }
                        Button(action: addFriend) {
                            Text(MSG("friends_add_confirm")).bold()
                        }
                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                ForEach(friends) { friend in
                    HStack {
                        Text(friend.name)
                        Spacer()
                        Button {
                            editingFriend = friend
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.borderless)
                    }
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
            .sheet(item: $editingFriend) { friend in
                EditFriendSheet(friend: friend)
            }
        }
    }

    private func addFriend() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(Friend(name: trimmed))
        try? modelContext.save()
        newName = ""
        showingAddField = false
    }

    private func deleteFriends(at offsets: IndexSet) {
        for idx in offsets { modelContext.delete(friends[idx]) }
        try? modelContext.save()
    }
}

// MARK: - Edit Sheet

private struct EditFriendSheet: View {
    @Bindable var friend: Friend
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var editedName: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField(MSG("friends_name_placeholder"), text: $editedName)
                        .focused($focused)
                }
            }
            .navigationTitle(MSG("friends_edit_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("edit_player_save")) {
                        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        friend.name = trimmed
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("edition_cancel")) { dismiss() }
                }
            }
            .onAppear {
                editedName = friend.name
                focused = true
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview {
    FriendsListView()
}
