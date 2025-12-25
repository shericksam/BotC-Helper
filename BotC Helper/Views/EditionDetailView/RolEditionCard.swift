//
//  RolEditionCard.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct RolEditionCard: View {
    let rol: RoleDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                RolIcon(name: rol.id)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(rol.nameLocalized())
                    .font(.title2)
                    .bold()
                if let team = rol.team {
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
            if !rol.abilityLocalized().isEmpty {
                Text(MSG("role_ability_label", rol.abilityLocalized()))
                    .font(.body)
            }
            if !rol.remindersLocalized().isEmpty {
                Text(MSG("role_reminders", rol.remindersLocalized().joined(separator: ", ")))
                    .font(.footnote)
            }
            if !rol.remindersGlobalLocalized().isEmpty {
                Text(MSG("role_global_reminders", rol.remindersGlobalLocalized().joined(separator: ", ")))
                    .font(.footnote)
            }
            if !rol.firstNightReminderLocalized().isEmpty {
                Text(MSG("role_first_night", rol.firstNightReminderLocalized()))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            if !rol.otherNightReminderLocalized().isEmpty {
                Text(MSG("role_other_night", rol.otherNightReminderLocalized()))
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
