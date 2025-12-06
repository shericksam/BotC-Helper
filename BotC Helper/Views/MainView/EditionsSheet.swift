//
//  EditionsSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct EditionsSheet: View {
    @State var editions: [EditionSummary] = EditionSummary.defaultEditions
    @State private var selectedEdition: EditionData? // Para navegación/Sheet
    @State private var loading = false
    @State private var showDetail = false
    @State private var showingCreateEdition = false

    // Puedes agregar lógica para agregar/editar/borrar ediciones

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
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
                                Divider()
                            }
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                            .padding(.bottom, 12)
                        }
                        .padding(.horizontal)
                    }
                }
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

    func loadEditionDetails(edition: EditionSummary) {
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
}

#Preview {
    EditionsSheet()
}
