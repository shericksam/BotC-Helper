//
//  ManageFabledSheet.swift
//  BotC Helper
//

import SwiftUI

struct ManageFabledSheet: View {
    @Bindable var board: BoardState
    let allFabled: [RoleDefinitionModel]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(allFabled, id: \.id) { fabled in
                let isActive = board.activeFabledIds.contains(fabled.id)
                Button {
                    if isActive {
                        board.activeFabledIds.removeAll { $0 == fabled.id }
                    } else {
                        board.activeFabledIds.append(fabled.id)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isActive ? "star.circle.fill" : "star.circle")
                            .font(.title3)
                            .foregroundColor(isActive ? .yellow : .secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fabled.nameLocalized())
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                            let ability = fabled.abilityLocalized()
                            if !ability.isEmpty {
                                Text(ability)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(MSG("fabled_manage_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MSG("close")) { dismiss() }
                }
            }
        }
    }
}
