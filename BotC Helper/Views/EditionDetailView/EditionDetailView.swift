//
//  EditionDetailView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct EditionDetailView: View {
    let editionMeta: EditionData
    @State private var isExpandedFirstNigth = false
    @State private var isExpandedOtherNigth = false
    @State private var searchText: String = ""

//    var teamSections: [(Team, [RoleDefinition])] {
//        // Orden de secciones deseado
//        let order: [Team] = [.townsfolk, .outsider, .minion, .demon, .traveller, .fabled]
//        return order.compactMap { team in
//            let chars = editionMeta.characters.filter { $0.team == team }
//            return chars.isEmpty ? nil : (team, chars)
//        }
//    }

    var groupedRoles: [(Team, [RoleDefinition])] {
        Team.allCases.compactMap { team in
            let filtered = editionMeta.characters.filter {
                $0.team == team &&
                (searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()))
            }
            return filtered.isEmpty ? nil : (team, filtered)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado edición
                Group {
                    if let author = editionMeta.meta.author {
                        Text("Autor: \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Divider()
                    if !editionMeta.meta.firstNight.isEmpty {
                        DisclosureGroup("Orden de noche inicial", isExpanded: $isExpandedFirstNigth) {
                            NightOrderView(order: editionMeta.meta.firstNight, roles: editionMeta.characters)
                                .padding()
                        }
                        .padding()
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }

                    if !editionMeta.meta.otherNight.isEmpty {
                        DisclosureGroup("Orden de otras noches", isExpanded: $isExpandedOtherNigth) {
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

                // Personajes
                ForEach(groupedRoles, id: \.0) { (team, chars) in
                    Section(header: Text(team.displayName)
                        .font(.title2)
                        .padding(.vertical, 4)
                        .foregroundColor(team.color)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(team.color.opacity(0.12).cornerRadius(8))
                    ) {
                        ForEach(chars) { character in
                            EditionCharacterCard(character: character)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Buscar rol por nombre")

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
                        if orderLabelsES[item] != nil {
                            // Noche, amanecer o info especial
                            HStack(spacing: 8) {
                                Image(item)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(5)
                                Text(item.capitalized)
                                    .font(.body)
                            }
                        } else if let role = roles.first(where: { $0.id == item }) {
                            // Es un rol, muestra icono y nombre bonito
                            HStack(spacing: 8) {
                                RolIcon(name: role.id)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(5)
                                Text(role.name)
                                    .font(.body)
                            }
                        } else {
                            // ¿Otro identificador raro? Solo muestra su nombre sin prefijo
                            Text(item.replacingOccurrences(of: "secta_", with: ""))
                        }
                    }
                }
            }
        }

        // Opción: Cambia el ícono para eventos especiales
        func iconSpecial(for item: String) -> String {
            switch item {
            case "dusk": return "moon.stars.fill"
            case "dawn": return "sun.max.fill"
            case "minioninfo": return "person.2.wave.2.fill"
            case "demoninfo": return "flame"
            default: return "circle"
            }
        }
}

let orderLabelsES: [String: String] = [
    "dusk": "Anochecer",
    "dawn": "Amanecer",
    "minioninfo": "Info de Esbirros",
    "demoninfo": "Info de Demonio"
]

//#Preview {
//    EditionDetailView(editionMeta: EditionDataModel.Mock.editionData!)
//}
//
//
//func mockLoadEditionDetails(edition: EditionSummaryModel) -> EditionDataModel? {
//    if let url = Bundle.main.url(forResource: edition.fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json"),
//       let loaded = try? loadEdition(from: url) {
//        return loaded
//    } else {
//        return nil
//        // Maneja error de carga aquí si quieres
//    }
//}
