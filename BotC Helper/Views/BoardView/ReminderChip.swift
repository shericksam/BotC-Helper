//
//  ReminderChip.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 19/04/26.
//

import SwiftUI

struct ReminderChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.9))
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
    }
}
