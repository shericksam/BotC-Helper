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
    var editingEdition: EditionData? = nil  // Ahora el modelo SwiftData

    @State private var isUpdate = false
    @State private var searchText: String = ""
    @State private var name = ""
    @State private var author = ""
    @State private var selectedRoles: Set<RoleDefinition> = []

    @Query(sort: \RoleDefinition.name) var allRoles: [RoleDefinition]
    @Environment(\.dismiss) var dismiss

    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            let filtered = allRoles.filter {
                $0.team == team &&
                (searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()))
            }.sorted(by: { $0.name < $1.name })
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Nombre de la edición") {
                    TextField("Nombre", text: $name)
                }
                Section("Autor") {
                    TextField("Autor", text: $author)
                }
                ForEach(groupedRoles, id: \.0) { (team, roles) in
                    Section(header: Text(team.displayName).foregroundColor(team.color)) {
                        ForEach(roles) { role in
                            HStack {
                                RolIcon(name: role.id)
                                    .frame(width: 32, height: 32)
                                Text(role.name)
                                Spacer()
                                Button(selectedRoles.contains(role) ? "Quitar" : "Agregar") {
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
            .searchable(text: $searchText, prompt: "Buscar rol por nombre")
            .navigationTitle(isUpdate ? "Editar edición" : "Nueva Edición")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isUpdate ? "Actualizar" : "Guardar") {
                        saveEdition()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoles.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
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
        if let edition = editingEdition {
            // Actualiza meta y roles
            edition.meta.name = name
            edition.meta.author = author
            edition.characters = Array(selectedRoles)
            try? modelContext.save()
        } else {
            // Nueva edición
            let meta = EditionMeta(
                id: UUID().uuidString,
                name: name,
                author: author,
                firstNight: [],
                otherNight: []
            )
            let edition = EditionData(
                meta: meta,
                characters: Array(selectedRoles)
            )
            modelContext.insert(edition)
            try? modelContext.save()
        }
        dismiss()
    }
}
