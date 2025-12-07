//
//  EditionsSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct EditionsSheet: View {
    @State var editions: [EditionSummaryModel] = EditionSummaryModel.defaultEditions
    @State private var selectedEdition: EditionDataModel? // Para navegación/Sheet
    @State private var loading = false
    @State private var showDetail = false
    @State private var showingCreateEdition = false
    @State private var editingEdition: EditionSummaryModel? = nil

    // Puedes agregar lógica para agregar/editar/borrar ediciones

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(editions) { edition in
                        Button {
                            loadEditionDetails(edition: edition)
                        } label: {
                            VStack(alignment: .center) {
                                if let imageName = edition.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                }
                                Text(edition.name).font(.headline)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                        }
                        // Agrega un swipe actions solo si se puede borrar
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !edition.isFromBundle {
                                Button(role: .destructive) {
                                    deleteEdition(edition)
                                } label: {
                                    Label("Borrar", systemImage: "trash")
                                }
                            }
                            if !edition.isFromBundle {
                                Button {
                                    editEdition(edition)
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.yellow)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .sheet(item: $editingEdition, onDismiss: refreshEditions) { editionToEdit in
                EditionCreationView(editingEdition: editionToEdit)
            }
            .navigationTitle("Ediciones")
            .navigationDestination(isPresented: $showDetail) {
                if let data = selectedEdition {
                    EditionDetailView(editionMeta: data)
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateEdition = true }) {
                        Label("Crear edición", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateEdition) {
                EditionCreationView()
            }
        }
    }

    func deleteEdition(_ edition: EditionSummaryModel) {
        // Solo locales! (no las bundle)
        guard !edition.isFromBundle else { return }
        let url = getDocumentsDirectory().appendingPathComponent(edition.fileName)
        do {
            try FileManager.default.removeItem(at: url)
            // Remueve de la lista local
            editions.removeAll { $0.id == edition.id }
        } catch {
            // Manejo de error opcional
        }
    }

    func editEdition(_ edition: EditionSummaryModel) {
        // Abre la vista edición pre-rellena con esta edición
        editingEdition = edition
    }

    func loadEditionDetails(edition: EditionSummaryModel) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = editionURL(for: edition),
               let loaded = try? loadEdition(from: url) {
                DispatchQueue.main.async {
                    self.selectedEdition = loaded
                    self.showDetail = true
                    self.loading = false
                }
            } else {
                DispatchQueue.main.async { self.loading = false }
                // Maneja error de carga aquí si quieres
            }
        }
    }

    func refreshEditions() {
        // Tu función para recargar las ediciones de bundle+usuario
        editions = EditionSummaryModel.defaultEditions
    }
}

#Preview {
    EditionsSheet()
}
