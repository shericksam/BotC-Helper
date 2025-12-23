//
//  PlayerEditor.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct PlayerEditor: View {
    @Bindable var player: Player
    @Bindable var status: PlayerStatus
    var onSave: (PlayerStatus, [Int: String]) -> Void
    @Environment(\.dismiss) var dismiss
    var isMe: Bool
    var totalDays: Int
    var statusesByDay: [PlayerStatus]
    var currentDayIndex: Int
    var roles: [RoleDefinition]

    @State private var searchClaim: String = ""
    @State private var filteredRoles: [RoleDefinition] = []
    @State private var showRolesList = false
    @State private var editRole = false
    var selectedRole: RoleDefinition? {
        guard let id = player.claimRoleId else { return nil }
        return roles.first { $0.id == id }
    }
    @State var localPersonalNotes: [Int: String] = [:]

    var body: some View {
        NavigationView {
            Form {
                Section(MSG("edit_player_section_data")) {
                    TextField(MSG("edit_player_section_data"), text: $player.name)
                    if isMe {
                        Button(MSG("edit_player_section_editrole")) { editRole.toggle() }
                    }
                    if editRole || !isMe {
                        claimRol()
                    }
                }

                if let selected = selectedRole, !iAmBadGuy() {
                    Section(MSG("edit_player_section_declaredrole", selected.name)) {
                        RolIcon(name: selected.iconName ?? selected.id)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(selected.ability ?? MSG("edit_player_no_role_description"))
                            .font(.body)
                        if let reminder = selected.firstNightReminder {
                            Text(MSG("edit_player_first_night", reminder)).font(.footnote)
                        }
                        if let reminder = selected.otherNightReminder {
                            Text(MSG("edit_player_other_night", reminder)).font(.footnote)
                        }
                    }
                }

                Section(MSG("edit_player_section_actions")) {
                    Toggle(MSG("edit_player_toggle_vote"), isOn: $status.voted)
                    Toggle(MSG("edit_player_toggle_nominate"), isOn: $status.nominated)
                    Toggle(MSG("edit_player_toggle_dead"), isOn: $status.dead)
                }
                Section(MSG("edit_player_section_notes_today")) {
                    TextEditor(text: $status.notes)
                        .frame(height: 80)
                }
                Section(MSG("edit_player_section_notes_days")) {
                    ForEach(0..<totalDays, id: \.self) { dayIdx in
                        let s = statusesByDay[safe: dayIdx] ?? PlayerStatus(dayIndex: 0, seatNumber: player.seatNumber)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(MSG("edit_player_day", dayIdx + 1)).font(.headline)
                                if s.voted {
                                    Label(MSG("edit_player_toggle_vote"), systemImage: "checkmark.circle")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.green)
                                }
                                if s.nominated {
                                    Label(MSG("edit_player_toggle_nominate"), systemImage: "hand.point.up.left.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.blue)
                                }
                                if s.dead {
                                    Label(MSG("edit_player_toggle_dead"), systemImage: "xmark")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(.red)
                                }
                            }
                            TextEditor(
                                text: Binding(
                                    get: { localPersonalNotes[dayIdx] ?? "" },
                                    set: { localPersonalNotes[dayIdx] = $0 }
                                )
                            )
                            .frame(height: dayIdx == currentDayIndex ? 100 : 60)
                            .background(dayIdx == currentDayIndex ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .onAppear {
                for note in player.personalNotes {
                    self.localPersonalNotes[note.dayIndex] = note.text
                }
            }
            .navigationTitle(titleNav())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("edit_player_save")) {
                        onSave(status, localPersonalNotes)
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
    func claimRol() -> some View {
        VStack(alignment: .leading) {
            TextField(
                MSG("edit_player_claim_placeholder"),
                text: Binding(
                    get: { searchClaim },
                    set: { newValue in
                        searchClaim = newValue
                        showRolesList = !newValue.isEmpty
                        filteredRoles = roles.filter {
                            $0.name.localizedCaseInsensitiveContains(newValue)
                        }
                        if newValue.isEmpty {
                            player.claimRoleId = nil
                        }
                        if let exact = roles.first(where: { $0.name.caseInsensitiveCompare(newValue) == .orderedSame }) {
                            player.claimRoleId = exact.id
                            player.claimManual = ""
                        } else {
                            player.claimRoleId = nil
                            player.claimManual = newValue
                        }
                    }
                )
            )
            .onAppear {
                if let rid = player.claimRoleId,
                   let rolename = roles.first(where: { $0.id == rid })?.name {
                    searchClaim = rolename
                } else {
                    searchClaim = player.claimManual
                }
            }
            if showRolesList && !filteredRoles.isEmpty {
                List(filteredRoles.prefix(3), id: \.id) { role in
                    Button {
                        player.claimRoleId = role.id
                        player.claimManual = ""
                        searchClaim = role.name
                        showRolesList = false
                    } label: {
                        HStack {
                            RolIcon(name: role.iconName ?? role.id)
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(role.name)
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
    }

    func iAmBadGuy() -> Bool {
        isMe && (selectedRole?.team == .demon || selectedRole?.team == .minion)
    }
}
