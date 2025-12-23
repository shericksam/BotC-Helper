//
//  RolIcon.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 06/12/25.
//

import SwiftUI

struct RolIcon: View {
    let name: String

    var body: some View {
        Image(getImage(by: name))
            .resizable()
            .scaledToFit()
    }

    func getImage(by name: String) -> String {
        name.replacing("secta_", with: "")
    }
}


#Preview {
    RolIcon(name: "grandmother")
        .frame(width: 40, height: 60)
}
