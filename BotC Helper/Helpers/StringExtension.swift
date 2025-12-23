//
//  StringExtension.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 23/12/25.
//

import Foundation

@inlinable
public func LocalizedString(_ key: String, comment: String = "") -> String {
    NSLocalizedString(key, comment: comment)
}

@inlinable
public func MSG(_ key: String, comment: String = "") -> String {
    LocalizedString(key, comment: comment)
}

@inlinable
public func MSG(_ key: String, _ param: CVarArg, _ comment: String = "") -> String {
    let raw = LocalizedString(key, comment: comment)
    return String(format: raw, param)
}

@inlinable
public func MSG(_ key: String, _ param1: CVarArg, _ param2: CVarArg, _ comment: String = "") -> String {
    let raw = LocalizedString(key, comment: comment)
    return String(format: raw, param1, param2)
}
