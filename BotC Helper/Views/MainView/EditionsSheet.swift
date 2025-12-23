//
//  EditionsSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct EditionsSheet: View {
    @Query(sort: \EditionData.id) var allEditions: [EditionData]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedEdition: EditionData?
    @State private var showDetail = false
    @State private var showingCreateEdition = false
    @State private var editingEdition: EditionData? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(allEditions) { edition in
                    Button {
                        selectedEdition = edition
                        showDetail = true
                    } label: {
                        VStack(alignment: .center) {
                            if let imageName = edition.meta.imageName, !imageName.isEmpty {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                            }
                            Text(edition.meta.name)
                                .font(.headline).padding()
                        }
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 1)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Solo permite borrar/editar si NO es de bundle
                        if edition.meta.author != "Oficial" { // O tu flag
                            Button(role: .destructive) {
                                deleteEdition(edition)
                            } label: {
                                Label("Borrar", systemImage: "trash")
                            }
                            Button {
                                editingEdition = edition
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.yellow)
                        }
                    }
                }
            }
            .listStyle(.plain)
            // Sheet para editar/crear
            .sheet(item: $editingEdition) { edition in
                EditionCreationView(editingEdition: edition)
            }
            .sheet(isPresented: $showingCreateEdition) {
                EditionCreationView()
            }
            .navigationTitle("Ediciones")
            .navigationDestination(isPresented: $showDetail) {
                if let edition = selectedEdition {
                    EditionDetailView(editionMeta: edition)
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
        }
    }

    func deleteEdition(_ edition: EditionData) {
        modelContext.delete(edition)
        try? modelContext.save()
    }

}

#Preview {
    EditionsSheet()
}
