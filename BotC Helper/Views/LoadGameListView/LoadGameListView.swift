//
//  LoadGameListView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct LoadGameListView: View {
    var onLoad: (BoardState) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var fileNames: [String] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(fileNames, id: \.self) { name in
                    Button(action: {
                        if let loaded = loadBoardState(fileName: name.replacingOccurrences(of: ".json", with: "")) {
                            onLoad(loaded)
                            dismiss()
                        }
                    }) {
                        Text(name.replacingOccurrences(of: ".json", with: ""))
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        let name = fileNames[i]
                        deleteSavedGame(name: name)
                    }
                    loadFiles() // recarga archivos
                }
            }
            .navigationTitle("Partidas Anteriores")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .onAppear(perform: loadFiles)
    }

    func loadFiles() {
        let dir = getDocumentsDirectory()
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
            self.fileNames = files.filter { $0.hasSuffix(".json") }
        }
    }

    func deleteSavedGame(name: String) {
        let url = getDocumentsDirectory().appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
    }
}

#Preview {
    LoadGameListView(onLoad: { _ in })
}
