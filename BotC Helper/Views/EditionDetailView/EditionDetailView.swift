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

    var teamSections: [(Team, [RoleDefinition])] {
        // Orden de secciones deseado
        let order: [Team] = [.townsfolk, .outsider, .minion, .demon, .traveller, .fabled]
        return order.compactMap { team in
            let chars = editionMeta.characters.filter { $0.team == team }
            return chars.isEmpty ? nil : (team, chars)
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

                    DisclosureGroup("ORDEN DE NOCHE INICIAL", isExpanded: $isExpandedFirstNigth) {
                        NightOrderView(order: editionMeta.meta.firstNight)
                            .padding()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 1)

                    DisclosureGroup("ORDEN DE OTRAS NOCHES", isExpanded: $isExpandedFirstNigth) {
                        NightOrderView(order: editionMeta.meta.otherNight)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 1)

                    Divider()
                }

                // Personajes
                ForEach(teamSections, id: \.0) { (team, chars) in
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
            }
            .padding()
        }
        .navigationTitle(editionMeta.meta.name)
    }
}

struct NightOrderView: View {
    let order: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(order, id: \.self) { item in
                HStack {
                    RolIcon(name: item)
                }
            }
        }
    }
}


#Preview {
    EditionDetailView(editionMeta: EditionData.Mock.editionData!)
}


func mockLoadEditionDetails(edition: EditionSummary) -> EditionData? {
    if let url = Bundle.main.url(forResource: edition.fileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json"),
       let loaded = try? loadEdition(from: url) {
        return loaded
    } else {
        return nil
        // Maneja error de carga aquí si quieres
    }
}
