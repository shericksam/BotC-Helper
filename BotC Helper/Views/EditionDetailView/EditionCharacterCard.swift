//
//  EditionCharacterCard.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct EditionCharacterCard: View {
    let character: RoleDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                RolIcon(name: character.id)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(character.name)
                    .font(.title2)
                    .bold()
                if let team = character.team {
                    Text(MSG("role_team_label", team.displayName))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(team.color.opacity(0.15))
                        .foregroundColor(team.color)
                        .cornerRadius(6)
                }
                Spacer()
            }
            if let ability = character.ability {
                Text(MSG("role_ability_label", ability))
                    .font(.body)
            }
            if let reminders = character.reminders, !reminders.isEmpty {
                Text(MSG("role_reminders", reminders.joined(separator: ", ")))
                    .font(.footnote)
            }
            if let global = character.remindersGlobal, !global.isEmpty {
                Text(MSG("role_global_reminders", global.joined(separator: ", ")))
                    .font(.footnote)
            }
            if let fn = character.firstNightReminder {
                Text(MSG("role_first_night", fn))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if let on = character.otherNightReminder {
                Text(MSG("role_other_night", on))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 1)
        .padding(.bottom, 12)
    }
}
