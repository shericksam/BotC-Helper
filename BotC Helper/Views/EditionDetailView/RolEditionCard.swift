//
//  RolEditionCard.swift
//  BotC Helper
//

import SwiftUI

struct RolEditionCard: View {
    let rol: RoleDefinition
    @State private var expanded = false

    var body: some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
            VStack(alignment: .leading, spacing: 0) {

                // Always-visible row
                HStack(spacing: 12) {
                    RolIcon(name: rol.id)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(rol.nameLocalized())
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            if let team = rol.team {
                                Text(team.displayName)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(team.color.opacity(0.15))
                                    .foregroundColor(team.color)
                                    .clipShape(Capsule())
                            }
                        }

                        if !rol.abilityLocalized().isEmpty {
                            Text(rol.abilityLocalized())
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(expanded ? nil : 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(12)

                // Expanded detail
                if expanded {
                    Divider().padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        if !rol.remindersLocalized().isEmpty {
                            detailRow(
                                icon: "tag.fill", color: .blue,
                                label: MSG("role_reminders", rol.remindersLocalized().joined(separator: ", "))
                            )
                        }
                        if !rol.remindersGlobalLocalized().isEmpty {
                            detailRow(
                                icon: "tag.circle.fill", color: .teal,
                                label: MSG("role_global_reminders", rol.remindersGlobalLocalized().joined(separator: ", "))
                            )
                        }
                        if !rol.firstNightReminderLocalized().isEmpty {
                            detailRow(
                                icon: "moon.stars.fill", color: .indigo,
                                label: MSG("role_first_night", rol.firstNightReminderLocalized())
                            )
                        }
                        if !rol.otherNightReminderLocalized().isEmpty {
                            detailRow(
                                icon: "moon.fill", color: .purple,
                                label: MSG("role_other_night", rol.otherNightReminderLocalized())
                            )
                        }
                    }
                    .padding(12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func detailRow(icon: String, color: Color, label: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
