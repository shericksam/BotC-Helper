//
//  ScriptImporter.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import Foundation

struct ScriptImporter {

    // Each array element can be a plain string ("pixie") or an object ({"id":"_meta","name":"..."})
    private enum ScriptEntry: Decodable {
        case string(String)
        case object(id: String, name: String?, author: String?)

        private enum CodingKeys: String, CodingKey { case id, name, author }

        init(from decoder: Decoder) throws {
            if let raw = try? decoder.singleValueContainer().decode(String.self) {
                self = .string(raw)
                return
            }
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self = .object(
                id: try c.decode(String.self, forKey: .id),
                name: try c.decodeIfPresent(String.self, forKey: .name),
                author: try c.decodeIfPresent(String.self, forKey: .author)
            )
        }

        var roleId: String {
            switch self {
            case .string(let s): return s
            case .object(let id, _, _): return id
            }
        }

        var metaName: String? {
            guard case .object(_, let name, _) = self else { return nil }
            return name
        }

        var metaAuthor: String? {
            guard case .object(_, _, let author) = self else { return nil }
            return author
        }

        var isMeta: Bool { roleId == "_meta" }
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
        guard let entries = try? JSONDecoder().decode([ScriptEntry].self, from: data) else {
            throw ImportError.invalidFormat
        }

        let meta = entries.first(where: { $0.isMeta })
        let scriptName = meta?.metaName ?? MSG("import_script_default_name")
        let author = meta?.metaAuthor ?? ""

        var matched: [RoleDefinition] = []
        var unmatched: [String] = []

        for entry in entries where !entry.isMeta {
            let entryId = entry.roleId.lowercased()
            if let role = allRoles.first(where: { $0.id.lowercased() == entryId }) {
                if !matched.contains(where: { $0.id == role.id }) {
                    matched.append(role)
                }
            } else {
                unmatched.append(entry.roleId)
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
