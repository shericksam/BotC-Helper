//
//  EditionSummaryModel.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import Foundation

struct EditionSummaryModel: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let imageName: String?
    var isFromBundle: Bool = true
}


extension EditionSummaryModel {
    static var defaultEditions: [EditionSummaryModel] {
        let defauls: [EditionSummaryModel] =
            [
                    EditionSummaryModel(id: "tb", name: "Trouble Brewing", fileName: "trouble_brewing.json", imageName: "logo_trouble_brewing"),
                    EditionSummaryModel(id: "s&v", name: "Sects & Violets", fileName: "sects_and_violets.json", imageName: "logo_sects_and_violets"),
                    EditionSummaryModel(id: "bmr", name: "Bad Moon Rising", fileName: "bad_moon_rising.json", imageName: "logo_bad_moon_rising")
            ]
        let editionURLs = allEditionFiles()
        let editions: [EditionSummaryModel] = editionURLs.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let jsonArr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let meta = jsonArr.first, let id = meta["id"] as? String,
                  let name = meta["name"] as? String
            else { return nil }
            let logo = meta["logo"] as? String
            return EditionSummaryModel(id: id, name: name, fileName: url.lastPathComponent, imageName: logo, isFromBundle: false)
        }
        return defauls + editions
    }
}
