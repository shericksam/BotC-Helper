//
//  EditionsSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct EditionsSheet: View {
    @Query(sort: \EditionData.id) var allEditions: [EditionData]
    @Query(sort: \BoardState.suggestedName) var allGames: [BoardState]
    @Query(sort: \RoleDefinition.id) var allRoles: [RoleDefinition]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedEdition: EditionData?
    @State private var showDetail = false
    @State private var showingCreateEdition = false
    @State private var editingEdition: EditionData? = nil
    @State private var showingImportScript = false
    @State private var showImportAlert = false
    @State private var importAlertMessage = ""

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
                        if edition.meta.author != "Steven Medway" {
                            Button(role: .destructive) {
                                deleteEdition(edition)
                            } label: {
                                Label(MSG("edit_sheet_delete"), systemImage: "trash")
                            }
                            Button {
                                editingEdition = edition
                            } label: {
                                Label(MSG("edit_sheet_edit"), systemImage: "pencil")
                            }
                            .tint(.yellow)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .sheet(item: $editingEdition) { edition in
                EditionCreationView(editingEdition: edition)
            }
            .sheet(isPresented: $showingCreateEdition) {
                EditionCreationView()
            }
            .navigationTitle(MSG("edit_sheet_title"))
            .navigationDestination(isPresented: $showDetail) {
                if let edition = selectedEdition {
                    EditionDetailView(editionMeta: edition)
                } else {
                    EmptyView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingCreateEdition = true }) {
                            Label(MSG("edit_sheet_create"), systemImage: "plus")
                        }
                        Button(action: { showingImportScript = true }) {
                            Label(MSG("import_script"), systemImage: "arrow.down.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImportScript,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url): performImport(from: url)
                case .failure: showError(MSG("import_script_error"))
                }
            }
            .alert(MSG("import_script_error"), isPresented: $showImportAlert) {
                Button(MSG("close"), role: .cancel) { }
            } message: {
                Text(importAlertMessage)
            }
        }
    }

    func deleteEdition(_ edition: EditionData) {
        for board in allGames where board.edition == edition {
            board.edition = nil
        }
        modelContext.delete(edition)
        try? modelContext.save()
    }

    private func performImport(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError(MSG("import_script_error"))
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let result = try ScriptImporter.importScript(from: data, allRoles: allRoles)

            let meta = EditionMeta(
                id: UUID().uuidString,
                name: result.scriptName,
                author: result.author
            )
            modelContext.insert(meta)

            let edition = EditionData(meta: meta, characters: result.matchedRoles)
            modelContext.insert(edition)
            try? modelContext.save()

            if !result.unmatchedIds.isEmpty {
                importAlertMessage = MSG("import_script_partial", result.unmatchedIds.joined(separator: ", "))
                showImportAlert = true
            }
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        importAlertMessage = message
        showImportAlert = true
    }
}

#Preview {
    EditionsSheet()
}
