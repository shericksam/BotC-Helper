//
//  EditionCreationView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI
import SwiftData

struct EditionCreationView: View {
    @Environment(\.modelContext) private var modelContext
    var editingEdition: EditionData? = nil

    @State private var isUpdate = false
    @State private var searchText: String = ""
    @State private var name = ""
    @State private var author = ""
    @State private var selectedRoles: Set<RoleDefinition> = []

    @Query(sort: \RoleDefinition.name) var allRoles: [RoleDefinition]
    @Query(sort: \Jinx.id) var allJinxes: [Jinx]
    @Environment(\.dismiss) var dismiss

    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            let filtered = allRoles.filter {
                $0.team == team &&
                (searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText))
            }.sorted(by: { $0.name < $1.name })
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(MSG("edition_section_name")) {
                    TextField(MSG("edition_section_name"), text: $name)
                }
                Section(MSG("edition_section_author")) {
                    TextField(MSG("edition_section_author"), text: $author)
                }
                ForEach(groupedRoles, id: \.0) { (team, roles) in
                    Section(header: Text(MSG("edition_team_\(team.rawValue)")).foregroundColor(team.color)) {
                        ForEach(roles) { role in
                            HStack {
                                RolIcon(name: role.id)
                                    .frame(width: 32, height: 32)
                                Text(role.name)
                                Spacer()
                                Button(selectedRoles.contains(role) ? MSG("edition_role_remove") : MSG("edition_role_add")) {
                                    if selectedRoles.contains(role) {
                                        selectedRoles.remove(role)
                                    } else {
                                        selectedRoles.insert(role)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: MSG("edition_search_roles_prompt"))
            .navigationTitle(isUpdate ? MSG("edition_edit_title") : MSG("edition_creation_title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isUpdate ? MSG("edition_update") : MSG("edition_save")) {
                        saveEdition()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoles.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(MSG("edition_cancel")) { dismiss() }
                }
            }
            .onAppear {
                if let edition = editingEdition {
                    isUpdate = true
                    name = edition.meta.name
                    author = edition.meta.author ?? ""
                    selectedRoles = Set(edition.characters)
                }
            }
        }
    }

    func saveEdition() {
        let selectedRoleIds = Set(selectedRoles.map { $0.id })
        let applicableJinxes = allJinxes.filter { jinx in
            Set(jinx.roles).isSubset(of: selectedRoleIds)
        }

        if let edition = editingEdition {
            edition.meta.name = name
            edition.meta.author = author
            edition.characters = Array(selectedRoles)
            edition.jinxes = applicableJinxes
            try? modelContext.save()
        } else {
            let meta = EditionMeta(
                id: UUID().uuidString,
                name: name,
                author: author,
                firstNight: [],
                otherNight: []
            )
            let edition = EditionData(
                meta: meta,
                characters: Array(selectedRoles),
                jinxes: applicableJinxes
            )
            modelContext.insert(edition)
            try? modelContext.save()
        }
        dismiss()
    }
}
