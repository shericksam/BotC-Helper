//
//  StyledSection.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 24/12/25.
//

import SwiftUI

struct StyledSection<Content: View>: View {
    let header: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(header)
                .font(.headline)
                .bold()
                .foregroundColor(.gray)
                .padding(.bottom, 2)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 8) {
                content()
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal)
    }
}

#Preview {
    StyledSection(header: "Player Data") {
        HStack {
            Text("text")
            Spacer()
        }
    }
    StyledSection(header: MSG("edit_player_section_actions")) {
        VStack {
            Toggle(MSG("edit_player_toggle_vote"), isOn: .constant(true))
            Toggle(MSG("edit_player_toggle_nominate"), isOn: .constant(true))
            Toggle(MSG("edit_player_toggle_dead"), isOn: .constant(true))
        }
    }

    if let selected = rolesExample.first {
        StyledSection(header: MSG("edit_player_section_declaredrole", selected.nameLocalized())) {
            VStack {
                RolIcon(name: selected.id)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(selected.abilityLocalized().isEmpty ? MSG("edit_player_no_role_description") : selected.abilityLocalized())
                if !selected.firstNightReminderLocalized().isEmpty {
                    Text(MSG("edit_player_first_night", selected.firstNightReminderLocalized()))
                        .font(.footnote)
                }
                if !selected.otherNightReminderLocalized().isEmpty {
                    Text(MSG("edit_player_other_night", selected.otherNightReminderLocalized()))
                        .font(.footnote)
                }
            }
        }
    }
}
