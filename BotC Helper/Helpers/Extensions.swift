//
//  Extensions.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 22/12/25.
//

import Foundation

extension CGPoint {
    static func + (a: CGPoint, b: CGSize) -> CGPoint {
        CGPoint(x: a.x + b.width, y: a.y + b.height)
    }
}

// Safe subscript para arrays (opcional)
public extension Array {
    subscript(safe idx: Int) -> Element? { (startIndex..<endIndex).contains(idx) ? self[idx] : nil }
}

extension Dictionary where Key == String, Value == String {
    func localized(_ defaultLang: String = "en") -> String {
        let preferred = Locale.preferredLanguages
            .compactMap { $0.components(separatedBy: "-").first }
        for lang in preferred {
            if let str = self[lang], !str.isEmpty { return str }
        }
        if let en = self[defaultLang], !en.isEmpty { return en }
        if let any = self.values.first { return any }
        return ""
    }
}
