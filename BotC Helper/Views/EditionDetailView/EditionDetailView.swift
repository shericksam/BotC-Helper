//
//  EditionDetailView.swift
//  BotC Helper
//

import SwiftUI
import SwiftData

struct EditionDetailView: View {
    let editionMeta: EditionData
    @State private var searchText = ""
    @State private var expandedTeams: Set<Team> = Set(Team.allCases)

    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            guard team != .fabled else { return nil }
            let filtered = editionMeta.characters.filter {
                $0.team == team &&
                (searchText.isEmpty || $0.nameLocalized().localizedCaseInsensitiveContains(searchText))
            }.sorted { $0.nameLocalized() < $1.nameLocalized() }
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var fabledRoles: [RoleDefinition] {
        editionMeta.characters.filter {
            $0.team == .fabled &&
            (searchText.isEmpty || $0.nameLocalized().localizedCaseInsensitiveContains(searchText))
        }.sorted { $0.nameLocalized() < $1.nameLocalized() }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Author + team count chips
                headerSection

                // Night order
                if !editionMeta.meta.firstNight.isEmpty || !editionMeta.meta.otherNight.isEmpty {
                    nightOrderSection
                }

                // Jinxes
                if !editionMeta.jinxes.isEmpty {
                    jinxSection
                }

                // Roles by team
                ForEach(groupedRoles, id: \.0) { team, roles in
                    teamSection(team: team, roles: roles)
                }

                // Fabled (storyteller-only, shown separately at the bottom)
                if !fabledRoles.isEmpty {
                    fabledSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle(editionMeta.meta.name)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: MSG("search_role_by_name"))
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let author = editionMeta.meta.author, !author.isEmpty {
                Label(author, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Team counts
            let counts: [(Team, Int)] = [Team.townsfolk, Team.outsider, Team.minion, Team.demon].compactMap { team in
                let n = editionMeta.characters.filter { $0.team == team }.count
                return n > 0 ? (team, n) : nil
            }
            if !counts.isEmpty {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(counts, id: \.0) { team, count in
                        VStack {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(team.color)
                                    .frame(width: 8, height: 8)
                                Text("\(count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(team.color)
                            }
                            Text(team.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(team.color.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Fabled

    private var fabledSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text(MSG("team_fabled"))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.yellow)
                    .textCase(.uppercase)
                Spacer()
                Text("\(fabledRoles.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.7))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            Text(MSG("fabled_detail_note"))
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(fabledRoles) { role in
                    RolEditionCard(rol: role)
                }
            }
        }
    }

    // MARK: - Night Order

    private var nightOrderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(MSG("edition_first_night"))
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            GroupBox {
                if !editionMeta.meta.firstNight.isEmpty {
                    NightOrderView(
                        label: MSG("edition_first_night"),
                        order: editionMeta.meta.firstNight,
                        roles: editionMeta.characters
                    )
                }
                if !editionMeta.meta.firstNight.isEmpty && !editionMeta.meta.otherNight.isEmpty {
                    Divider().padding(.vertical, 4)
                }
                if !editionMeta.meta.otherNight.isEmpty {
                    NightOrderView(
                        label: MSG("edition_other_night"),
                        order: editionMeta.meta.otherNight,
                        roles: editionMeta.characters
                    )
                }
            }
        }
    }

    // MARK: - Jinxes

    private var jinxSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(MSG("jinxes_title"))
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                ForEach(editionMeta.jinxes, id: \.id) { jinx in
                    JinxCard(jinx: jinx, characters: editionMeta.characters)
                }
            }
        }
    }

    // MARK: - Team section

    @ViewBuilder
    private func teamSection(team: Team, roles: [RoleDefinition]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Team header
            HStack {
                Circle().fill(team.color).frame(width: 10, height: 10)
                Text(team.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(team.color)
                    .textCase(.uppercase)
                Spacer()
                Text("\(roles.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(team.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Role cards
            VStack(spacing: 6) {
                ForEach(roles) { role in
                    RolEditionCard(rol: role)
                }
            }
        }
    }
}

// MARK: - Night Order

struct NightOrderView: View {
    let label: String
    let order: [String]
    let roles: [RoleDefinition]

    private let specialIcons: [String: String] = [
        "dusk":      "moon.stars.fill",
        "dawn":      "sun.max.fill",
        "minioninfo":"person.2.wave.2.fill",
        "demoninfo": "flame.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.bottom, 6)

            ForEach(Array(order.enumerated()), id: \.offset) { idx, item in
                HStack(spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 18, alignment: .trailing)

                    if let icon = specialIcons[item] {
                        Image(systemName: icon)
                            .resizable().scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.secondary)
                        Text(item.capitalized)
                            .font(.subheadline)
                    } else if let role = roles.first(where: { $0.id == item }) {
                        RolIcon(name: role.id)
                            .frame(width: 26, height: 26)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        Text(role.nameLocalized())
                            .font(.subheadline)
                    } else {
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                if idx < order.count - 1 {
                    Divider().padding(.leading, 28)
                }
            }
        }
    }
}

// MARK: - Jinx Card

private struct JinxCard: View {
    let jinx: Jinx
    let characters: [RoleDefinition]

    private func roleName(_ id: String) -> String {
        characters.first(where: { $0.id == id })?.nameLocalized()
            ?? id.capitalized
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Role icons
            HStack(spacing: -8) {
                ForEach(jinx.roles.prefix(2), id: \.self) { id in
                    RolIcon(name: id)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(jinx.roles.map { roleName($0) }.joined(separator: " + "))
                    .font(.caption.weight(.bold))
                    .foregroundColor(.primary)
                Text(jinx.desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NavigationStack {
        EditionDetailView(editionMeta: EditionDataModel.Mock.editionData.flatMap { _ in nil } ?? EditionData(
            meta: EditionMeta(id: "tb", name: "Trouble Brewing", author: "Steven Medway", firstNight: [], otherNight: []),
            characters: []
        ))
    }
}
