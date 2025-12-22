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
    var isMe: Bool = false

    var roles: [RoleDefinition] = []

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
                Section("Datos del Jugador") {
                    TextField("Nombre", text: $player.name)

                    if isMe {
                        Button("Editar rol") {
                            editRole.toggle()
                        }
                    }
                    if editRole || !isMe {
                        claimRol()
                    }
                }
                if let selected = selectedRole, !iAmBadGuy() {
                    Section("Rol declarado: \(selected.name)") {
                        RolIcon(name: selected.iconName ?? selected.id)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(selected.ability ?? "Sin descripción")
                            .font(.body)
                        if let reminder = selected.firstNightReminder {
                            Text("Noche inicial: \(reminder)").font(.footnote)
                        }
                        if let reminder = selected.otherNightReminder {
                            Text("Otras noches: \(reminder)").font(.footnote)
                        }
                    }
                }
                Section("Acciones (día actual)") {
                    Toggle("Votó", isOn: $status.voted)
                    Toggle("Nominó", isOn: $status.nominated)
                    Toggle("Muerto", isOn: $status.dead)
                }
                Section("Notas Día actual") {
                    TextEditor(text: $status.notes)
                        .frame(height: 80)
                }
            }
            .onAppear {
                for (day, note) in player.personalNotes {
                    self.localPersonalNotes[day] = note
                }
            }
            .navigationTitle("Editar Jugador \(player.seatNumber)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(status, localPersonalNotes)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    func claimRol() -> some View {
        VStack(alignment: .leading) {
            TextField(
                "Claim (rol declarado)",
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
                            player.claimManual = "" // Limpia claim manual
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
                List(filteredRoles.prefix(7), id: \.id) { role in
                    Button {
                        player.claimRoleId = role.id
                        player.claimManual = ""
                        searchClaim = role.name
                        showRolesList = false
                    } label: {
                        HStack{
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

