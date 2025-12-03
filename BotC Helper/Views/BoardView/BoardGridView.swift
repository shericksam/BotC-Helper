//
//  BoardGridView.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct SquareGridDemo: View {
    // 1. Define a responsive grid layout
    // This creates three columns that adapt to available space,
    // ensuring items are consistently sized.
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                // 2. Iterate to create multiple items
                ForEach(1..<50) { index in
                    GridItemView(index: index)
                }
            }
            .padding()
        }
    }
}

struct GridItemView: View {
    let index: Int

    var body: some View {
        Text("\(index)")
            .font(.largeTitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity) // 3. Allow view to expand to available width
            .aspectRatio(1.0, contentMode: .fit) // 4. Force a square aspect ratio (1:1)
            .background(Color.blue)
            // 5. Add the border to the entire view
            .border(Color.red, width: 2)
    }
}

// Preview provider for Xcode
#Preview {
    SquareGridDemo()
}
