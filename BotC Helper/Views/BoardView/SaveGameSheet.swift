//
//  SaveGameSheet.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct SaveGameSheet: View {
    @Binding var isPresented: Bool
    var suggestedName: String
    var onSave: (String) -> Void
    @State private var fileName: String

    init(isPresented: Binding<Bool>, suggestedName: String, onSave: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.suggestedName = suggestedName
        self.onSave = onSave
        self._fileName = State(initialValue: suggestedName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Nombre para la partida") {
                    TextField("Nombre de la partida", text: $fileName)
                }
            }
            .navigationTitle("Guardar Partida")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(fileName)
                        isPresented = false
                    }
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { isPresented = false }
                }
            }
        }
    }
}
