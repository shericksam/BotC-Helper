//
//  ScriptImporter.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import Foundation

struct ScriptImporter {

    private struct ScriptEntry: Decodable {
        let id: String
        let name: String?
        let author: String?
    }

    struct ImportResult {
        let scriptName: String
        let author: String
        let matchedRoles: [RoleDefinition]
        let unmatchedIds: [String]
    }

    enum ImportError: Error, LocalizedError {
        case invalidFormat
        case emptyScript

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return MSG("import_script_error")
            case .emptyScript: return MSG("import_script_empty")
            }
        }
    }

    static func importScript(from data: Data, allRoles: [RoleDefinition]) throws -> ImportResult {
        let entries = try JSONDecoder().decode([ScriptEntry].self, from: data)

        let metaEntry = entries.first(where: { $0.id == "_meta" })
        let scriptName = metaEntry?.name ?? MSG("import_script_default_name")
        let author = metaEntry?.author ?? ""

        let roleEntries = entries.filter { $0.id != "_meta" }

        var matched: [RoleDefinition] = []
        var unmatched: [String] = []

        for entry in roleEntries {
            if let role = allRoles.first(where: { $0.id.lowercased() == entry.id.lowercased() }) {
                if !matched.contains(where: { $0.id == role.id }) {
                    matched.append(role)
                }
            } else {
                unmatched.append(entry.id)
            }
        }

        if matched.isEmpty && unmatched.isEmpty {
            throw ImportError.emptyScript
        }

        return ImportResult(
            scriptName: scriptName,
            author: author,
            matchedRoles: matched,
            unmatchedIds: unmatched
        )
    }
}
