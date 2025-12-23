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
