//
//  EditionsSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct EditionsSheet: View {
//    @Binding var editions: [Edition]
    @Environment(\.dismiss) var dismiss
    @State private var showingAddEdition = false
    @State private var newEditionName = ""
    @State private var newEditionDescription = ""

    var body: some View {
        NavigationView {
            List {
                Text("")
//                ForEach($editions) { edition in
//                    VStack(alignment: .leading) {
//                        Text(edition.name)
//                            .font(.headline)
//                        Text(edition.description)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                .onDelete { offsets in
//                    editions.remove(atOffsets: offsets)
//                }
            }
            .navigationTitle("Ediciones")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showingAddEdition.toggle() }) {
                        Label("Añadir", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEdition) {
                NavigationView {
                    Form {
                        TextField("Nombre", text: $newEditionName)
                        TextField("Descripción", text: $newEditionDescription)
                    }
                    .navigationTitle("Nueva Edición")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
//                                let newEdition = Edition(name: newEditionName, description: newEditionDescription)
//                                editions.append(newEdition)
//                                newEditionName = ""
//                                newEditionDescription = ""
//                                showingAddEdition = false
                            }
                            .disabled(newEditionName.isEmpty)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") { showingAddEdition = false }
                        }
                    }
                }
            }
        }
    }
}
