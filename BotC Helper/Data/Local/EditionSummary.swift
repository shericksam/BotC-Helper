//
//  EditionSummary.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

struct EditionSummary: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let fileName: String // Por ejemplo: "trouble_brewing.json"
    let imageName: String?
}


extension EditionSummary {
    static var defaultEditions: [EditionSummary] {
        let defauls: [EditionSummary] =
            [
                    EditionSummary(id: "tb", name: "Trouble Brewing", fileName: "trouble_brewing.json", imageName: "logo_trouble_brewing"),
                    EditionSummary(id: "s&v", name: "Sects & Violets", fileName: "sects_and_violets.json", imageName: "logo_sects_and_violets"),
                    EditionSummary(id: "bmr", name: "Bad Moon Rising", fileName: "bad_moon_rising.json", imageName: "logo_bad_moon_rising")
            ]
        let editionURLs = allEditionFiles()
        let editions: [EditionSummary] = editionURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let jsonArr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let meta = jsonArr.first, let id = meta["id"] as? String,
                  let name = meta["name"] as? String
            else { return nil }
            let logo = meta["logo"] as? String
            return EditionSummary(id: id, name: name, fileName: url.lastPathComponent, imageName: logo)
        }
        return defauls + editions
    }
}
