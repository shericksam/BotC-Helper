//
//  EditionCreationView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct EditionCreationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var name = ""
    @State private var selectedRoles: Set<RoleDefinition> = []
    @State private var allRoles: [RoleDefinition] = loadPredefinedRoles()

    // Agrupa roles por equipo
    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            let filtered = allRoles.filter {
                $0.team == team &&
                (searchText.isEmpty ||
                 $0.name.lowercased().contains(searchText.lowercased()))
            }
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Nombre de la edición") {
                    TextField("Nombre", text: $name)
                }
                ForEach(groupedRoles, id: \.0) { (team, roles) in
                    Section(header: Text(team.displayName).foregroundColor(team.color)) {
                        ForEach(roles) { role in
                            HStack {
                                RolIcon(name: role.iconName)
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
            .navigationTitle("Nueva Edición")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveEdition()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoles.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    func saveEdition() {
        // Meta mínimo requerido, además puedes pedirlo en el formulario
        let meta: [String: Any] = [
            "id": UUID().uuidString,
            "name": name,
            "author": "usuario",
            "firstNight": [],   // puedes agregar interface para tomar el orden de noche
            "otherNight": []
        ]
        let fileName = name.replacingOccurrences(of: " ", with: "_").lowercased() + ".json"
        saveEdition(meta: meta, roles: Array(selectedRoles), fileName: fileName)
    }

    func saveEdition(meta: [String: Any], roles: [RoleDefinition], fileName: String) {
        // 1. Convierte los roles a [Any] (dictionaries)
        let rolesArr: [Any] = selectedRoles.compactMap { role in
            try? JSONSerialization.jsonObject(with: JSONEncoder().encode(role))
        }
        // 2. El array que irá al archivo
        var fullArray: [Any] = [meta]
        fullArray.append(contentsOf: rolesArr)

        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? JSONSerialization.data(withJSONObject: fullArray, options: .prettyPrinted) {
            try? data.write(to: url)
        }
    }

    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
