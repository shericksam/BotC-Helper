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
                Image(character.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(character.name)
                    .font(.title2)
                    .bold()
                if let team = character.team {
                    Text(team.displayName)
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
                Text(ability)
                    .font(.body)
            }
            if let reminders = character.reminders, !reminders.isEmpty {
                Text("Recordatorios: \(reminders.joined(separator: ", "))").font(.footnote)
            }
            if let global = character.remindersGlobal, !global.isEmpty {
                Text("Recordatorios Globales: \(global.joined(separator: ", "))").font(.footnote)
            }
            if let fn = character.firstNightReminder {
                Text("Noche inicial: \(fn)").font(.footnote).foregroundColor(.secondary)
            }
            if let on = character.otherNightReminder {
                Text("Otras noches: \(on)").font(.footnote).foregroundColor(.secondary)
            }
            if let special = character.special {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Especiales:").font(.footnote)
                    ForEach(special, id: \.name) { s in
                        Text("• \(s.name) (\(s.type)\(s.value != nil ? ": " + s.value! : ""))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
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

#Preview {
//    EditionCharacterCard(character: )
}
