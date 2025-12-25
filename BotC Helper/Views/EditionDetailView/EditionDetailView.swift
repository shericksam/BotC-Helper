//
//  EditionDetailView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI
import SwiftData

struct EditionDetailView: View {
    let editionMeta: EditionData
    @State private var isExpandedFirstNight = false
    @State private var isExpandedOtherNight = false
    @State private var searchText: String = ""

    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            let filtered = editionMeta.characters.filter {
                $0.team == team &&
                (searchText.isEmpty || $0.nameLocalized().localizedCaseInsensitiveContains(searchText))
            }.sorted(by: { $0.nameLocalized() < $1.nameLocalized() })
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado edición
                Group {
                    if let author = editionMeta.meta.author {
                        Text(MSG("edition_author", author))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Divider()
                    if !editionMeta.meta.firstNight.isEmpty {
                        DisclosureGroup(MSG("edition_first_night"), isExpanded: $isExpandedFirstNight) {
                            NightOrderView(order: editionMeta.meta.firstNight, roles: editionMeta.characters)
                                .padding()
                        }
                        .padding()
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }

                    if !editionMeta.meta.otherNight.isEmpty {
                        DisclosureGroup(MSG("edition_other_night"), isExpanded: $isExpandedOtherNight) {
                            NightOrderView(order: editionMeta.meta.otherNight, roles: editionMeta.characters)
                                .padding()
                        }
                        .padding()
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }
                    if !(editionMeta.meta.otherNight.isEmpty) && !(editionMeta.meta.firstNight.isEmpty) {
                        Divider()
                    }
                }

                // Jinxes
                if !editionMeta.jinxes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        Text(MSG("jinxes_title")).font(.headline)
                        ForEach(Array(editionMeta.jinxes), id: \Jinx.id) { (jinx: Jinx) in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("• \(jinx.desc)")
                                    .font(.body)
                                    .foregroundColor(.yellow)
                                if !jinx.roles.isEmpty {
                                    Text(MSG("jinxes_impacts", jinx.roles.joined(separator: ", ")))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Roles
                ForEach(groupedRoles, id: \.0) { (team, roles) in
                    Section(header: Text(team.displayName)
                        .font(.title2)
                        .padding(.vertical, 4)
                        .foregroundColor(team.color)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(team.color.opacity(0.12).cornerRadius(8))
                    ) {
                        ForEach(roles) { rol in
                            RolEditionCard(rol: rol)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: MSG("search_role_by_name"))
            }
            .padding()
        }
        .navigationTitle(editionMeta.meta.name)
    }
}

struct NightOrderView: View {
    let order: [String]
    let roles: [RoleDefinition]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(order, id: \.self) { item in
                HStack {
                    let label = nightOrderLabel(for: item)
                    if label != item + "_label" {
                        HStack(spacing: 8) {
                            Image(item)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .cornerRadius(5)
                            Text(item.capitalized)
                                .font(.body)
                        }
                    } else if let role = roles.first(where: { $0.id == item }) {
                        HStack(spacing: 8) {
                            RolIcon(name: role.id)
                                .frame(width: 50, height: 50)
                                .cornerRadius(5)
                            Text(role.nameLocalized())
                                .font(.body)
                        }
                    } else {
                        Text(item)
                    }
                }
            }
        }
    }

    func iconSpecial(for item: String) -> String {
        switch item {
        case "dusk": return "moon.stars.fill"
        case "dawn": return "sun.max.fill"
        case "minioninfo": return "person.2.wave.2.fill"
        case "demoninfo": return "flame"
        default: return "circle"
        }
    }

    func nightOrderLabel(for key: String) -> String {
        NSLocalizedString(key + "_label", comment: "")
    }
}
