//
//  AddReminderSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import SwiftUI
import SwiftData

struct AddReminderSheet: View {
    @Bindable var board: BoardState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let roles: [RoleDefinition]

    @State private var customText = ""

    struct ReminderOption: Identifiable {
        let id = UUID()
        let text: String
        let roleName: String
        let team: Team?
    }

    var roleReminderOptions: [ReminderOption] {
        var seen = Set<String>()
        return roles.flatMap { role -> [ReminderOption] in
            let all = role.remindersLocalized() + role.remindersGlobalLocalized()
            return all.filter { !$0.isEmpty }.compactMap { text in
                guard seen.insert(text).inserted else { return nil }
                return ReminderOption(text: text, roleName: role.nameLocalized(), team: role.team)
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(MSG("board_reminder_custom")) {
                    HStack {
                        TextField(MSG("board_reminder_custom_placeholder"), text: $customText)
                        Button(MSG("edition_role_add")) {
                            let trimmed = customText.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            addReminder(text: trimmed, colorName: "blue")
                        }
                        .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !roleReminderOptions.isEmpty {
                    Section(MSG("board_reminder_from_roles")) {
                        ForEach(roleReminderOptions) { option in
                            Button {
                                addReminder(text: option.text, colorName: colorName(for: option.team))
                            } label: {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(option.team?.color ?? .blue)
                                        .frame(width: 10, height: 10)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.text)
                                            .foregroundColor(.primary)
                                        Text(option.roleName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(MSG("board_add_reminder"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("edition_cancel")) { dismiss() }
                }
            }
        }
    }

    private func addReminder(text: String, colorName: String) {
        let token = ReminderToken(text: text, posX: 0.5, posY: 0.5, colorName: colorName)
        board.reminders.append(token)
        try? modelContext.save()
        dismiss()
    }

    private func colorName(for team: Team?) -> String {
        switch team {
        case .townsfolk:  return "blue"
        case .outsider:   return "teal"
        case .minion:     return "purple"
        case .demon:      return "red"
        case .traveller:  return "orange"
        case .fabled:     return "gray"
        default:          return "blue"
        }
    }
}
