//
//  PlayerEditor.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct PlayerEditor: View {
    @Bindable var player: Player
    @Bindable var status: PlayerStatus
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    var isMe: Bool
    var totalDays: Int
    var statusesByDay: [PlayerStatus]
    var currentDayIndex: Int
    var roles: [RoleDefinition]

    @Query(sort: \Friend.name) private var friends: [Friend]

    @State private var searchClaim: String = ""
    @State private var filteredRoles: [RoleDefinition] = []
    @State private var showRolesList = false
    @State private var editRole = false
    var selectedRole: RoleDefinition? {
        guard let id = player.claimRoleId else { return nil }
        return roles.first { $0.id == id }
    }
    @FocusState private var claimFieldFocused: Bool
    @State private var roleJustChosen = false

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                StyledSection(header: MSG("edit_player_section_data")) {
                    VStack {
                        HStack {
                            TextField(MSG("edit_player_section_data"), text: $player.name)
                            if !friends.isEmpty {
                                Menu {
                                    ForEach(friends) { friend in
                                        Button(friend.name) { player.name = friend.name }
                                    }
                                } label: {
                                    Image(systemName: "person.crop.circle")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        if isMe {
                            Divider()
                            Button(MSG("edit_player_section_editrole")) { editRole.toggle() }
                        }
                        if editRole || !isMe {
                            Divider()
                            claimRolField()
                        }
                    }
                }

                if let selected = selectedRole, !iAmBadGuy() {
                    StyledSection(header: MSG("edit_player_section_declaredrole", selected.nameLocalized())) {
                        VStack {
                            RolIcon(name: selected.id)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Divider()
                            Text(selected.abilityLocalized().isEmpty ? MSG("edit_player_no_role_description") : selected.abilityLocalized())
                            if !selected.firstNightReminderLocalized().isEmpty {
                                Divider()
                                Text(MSG("edit_player_first_night", selected.firstNightReminderLocalized()))
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)
                            }
                            if !selected.otherNightReminderLocalized().isEmpty {
                                Divider()
                                Text(MSG("edit_player_other_night", selected.otherNightReminderLocalized()))
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }

                StyledSection(header: MSG("edit_player_section_actions")) {
                    VStack {
                        Toggle(MSG("edit_player_toggle_vote"), isOn: $status.voted)
                        Divider()
                        Toggle(MSG("edit_player_toggle_nominate"), isOn: $status.nominated)
                        Divider()
                        Toggle(MSG("edit_player_toggle_dead"), isOn: Binding(
                            get: { status.dead },
                            set: { isDead in
                                status.dead = isDead
                                if !isDead {
                                    status.deathType = nil
                                } else if status.deathType == nil {
                                    status.deathType = "other"
                                }
                            }
                        ))
                        if status.dead {
                            Divider()
                            Picker(MSG("death_type_label"), selection: Binding(
                                get: { status.deathType ?? "other" },
                                set: { status.deathType = $0 }
                            )) {
                                Text(MSG("death_night_kill")).tag("nightKill")
                                Text(MSG("death_execution")).tag("execution")
                                Text(MSG("death_other")).tag("other")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }

                StyledSection(header: MSG("edit_player_section_notes_today")) {
                    TextEditor(text: $status.notes)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                        .padding(.vertical, 6)
                }
                StyledSection(header: MSG("edit_player_section_notes_days")) {
                    ForEach(player.personalNotes.sorted { $0.dayIndex < $1.dayIndex }, id: \.dayIndex) { note in
                        let dayIdx = note.dayIndex
                        let s = statusesByDay.first(where: { $0.dayIndex == dayIdx }) ?? PlayerStatus(dayIndex: dayIdx, seatNumber: player.seatNumber)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(MSG("edit_player_day", dayIdx + 1))
                                    .font(.headline.weight(dayIdx == currentDayIndex ? .bold : .regular))
                                    .foregroundColor(dayIdx == currentDayIndex ? .yellow : .primary)
                                Spacer()
                                if s.voted {
                                    Label(MSG("edit_player_toggle_vote"), systemImage: "checkmark.circle")
                                        .labelStyle(.iconOnly).foregroundColor(.green)
                                }
                                if s.nominated {
                                    Label(MSG("edit_player_toggle_nominate"), systemImage: "hand.point.up.left.fill")
                                        .labelStyle(.iconOnly).foregroundColor(.blue)
                                }
                                if s.dead {
                                    Label(MSG("edit_player_toggle_dead"), systemImage: "xmark")
                                        .labelStyle(.iconOnly).foregroundColor(.red)
                                }
                            }

                            TextEditor(
                                text: Binding(
                                    get: { note.text },
                                    set: { note.text = $0 }
                                )
                            )
                            .frame(height: dayIdx == currentDayIndex ? 100 : 60)
                            .background(dayIdx == currentDayIndex ? Color.yellow.opacity(0.18) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9)
                                    .stroke(dayIdx == currentDayIndex ? Color.yellow.opacity(0.7) : Color(.separator), lineWidth: dayIdx == currentDayIndex ? 2.5 : 1)
                            )
                            .shadow(color: dayIdx == currentDayIndex ? Color.yellow.opacity(0.21) : .clear, radius: 3)
                            .opacity(dayIdx == currentDayIndex ? 1 : 0.80)
                            .clipShape(RoundedRectangle(cornerRadius: 9))
                            if dayIdx != player.personalNotes.count - 1 {
                                Divider()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .onAppear {
                for dayIdx in 0..<totalDays {
                    if player.personalNotes.first(where: { $0.dayIndex == dayIdx }) == nil {
                        player.personalNotes.append(PersonalNote(dayIndex: dayIdx, text: ""))
                        player.personalNotes.sort { $0.dayIndex < $1.dayIndex }
                    }
                }
            }
            .navigationTitle(titleNav())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("edit_player_save")) {
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("edit_player_cancel")) { dismiss() }
                }
            }
        }
    }

    func titleNav() -> String {
        !player.name.isEmpty
            ? MSG("edit_player_nav", player.name)
            : MSG("edit_player_nav_unnamed", player.seatNumber)
    }

    @ViewBuilder
    func claimRolField() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                TextField(
                    MSG("edit_player_claim_placeholder"),
                    text: $searchClaim
                )
                .focused($claimFieldFocused)
                .onChange(of: searchClaim) { _, newValue in
                    filteredRoles = newValue.isEmpty
                        ? roles
                        : roles.filter { $0.nameLocalized().localizedCaseInsensitiveContains(newValue) }
                    showRolesList = !filteredRoles.isEmpty
                    if newValue.isEmpty {
                        player.claimRoleId = nil
                        player.claimManual = ""
                    } else if let exact = roles.first(where: { $0.nameLocalized().caseInsensitiveCompare(newValue) == .orderedSame }) {
                        player.claimRoleId = exact.id
                        player.claimManual = ""
                    } else {
                        player.claimRoleId = nil
                        player.claimManual = newValue
                    }
                }
                .onChange(of: claimFieldFocused) { _, focused in
                    if focused {
                        filteredRoles = searchClaim.isEmpty
                            ? roles
                            : roles.filter { $0.nameLocalized().localizedCaseInsensitiveContains(searchClaim) }
                        showRolesList = !filteredRoles.isEmpty
                    }
                }
                .onAppear {
                    if let rid = player.claimRoleId,
                       let rolename = roles.first(where: { $0.id == rid })?.nameLocalized() {
                        searchClaim = rolename
                    } else {
                        searchClaim = player.claimManual
                    }
                }

                if showRolesList && !filteredRoles.isEmpty && !roleJustChosen && claimFieldFocused {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredRoles.prefix(8), id: \.id) { role in
                            Button {
                                guard !roleJustChosen else { return }
                                roleJustChosen = true
                                player.claimRoleId = role.id
                                player.claimManual = ""
                                searchClaim = role.nameLocalized()
                                showRolesList = false
                                claimFieldFocused = false
                                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                                    roleJustChosen = false
                                }
                            } label: {
                                HStack {
                                    RolIcon(name: role.id)
                                        .frame(width: 42, height: 42)
                                    Text(role.nameLocalized()).fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if role != filteredRoles.prefix(8).last { Divider() }
                        }
                    }
                    .background(Color(.systemBackground).opacity(0.99))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 6)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 44) // para dejar debajo del TextField
                    .zIndex(101)
                    .transition(.opacity)
                }
            }
            .padding(.bottom, 6)
        }
    }

    func iAmBadGuy() -> Bool {
        isMe && (selectedRole?.team == .demon || selectedRole?.team == .minion)
    }
}

#Preview {
    let player = Player(seatNumber: 2, name: "test")
    let playerStatus: PlayerStatus = .init(dayIndex: 0)

    return PlayerEditor(player: player,
                        status: playerStatus,
                        onSave: { },
                        isMe: false,
                        totalDays: 10,
                        statusesByDay: [playerStatus],
                        currentDayIndex: 0,
                        roles: rolesExample)
}
