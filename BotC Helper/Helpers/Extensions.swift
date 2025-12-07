//
//  Extensions.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 07/12/25.
//

import Foundation

extension CGPoint {
    static func + (a: CGPoint, b: CGSize) -> CGPoint {
        CGPoint(x: a.x + b.width, y: a.y + b.height)
    }
}
