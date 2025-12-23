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
        return defauls
    }
}
