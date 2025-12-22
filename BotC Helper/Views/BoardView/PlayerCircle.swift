//
//  PlayerCircle.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct PlayerCircle: View {
    var player: Player
    var status: PlayerStatus
    var isMe: Bool
    var roles: [RoleDefinition]
    var onTap: () -> Void

    var claimedRole: RoleDefinition? {
        guard let id = player.claimRoleId else { return nil }
        return roles.first(where: { $0.id == id })
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .strokeBorder(isMe ? Color.green : (status.dead ? .red : Color.primaryBrown), lineWidth: 3)
                    .frame(width: 60, height: 60)
//                    .overlay(

//                    )
                    .background(
                        Image("background")
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    )
                VStack {
                    if !player.name.isEmpty {
                        Text(player.name)
                            .foregroundColor(.black)
                            .font(.caption)
                            .lineLimit(3)
                    } else {
                        Text("#\(player.seatNumber)")
                            .foregroundColor(.black)
                            .font(.headline)
                    }
                }
                // Voto
                if status.voted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .offset(x: -22, y: -22)
                }
                // Nominó
                if status.nominated {
                    Image(systemName: "hand.point.up.left.fill")
                        .foregroundColor(.blue)
                        .offset(x: 22, y: -22)
                }
                // Muerto (tachado X)
                if status.dead {
                    Image(systemName: "xmark")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                }
                // Rol asignado (opcional)
                if let role = claimedRole, !iAmBadGuy() {
                        RolIcon(name: role.id)
                            .frame(width: 70, height: 50)
                            .clipShape(Circle())
                            .offset(x: 0, y: -22)
                }
            }
            Group {
                if let role = claimedRole, !iAmBadGuy() {
                    Text(role.name)
                } else {
                    Text("Seat \(player.seatNumber)")
                }
            }
            .foregroundColor(.white)
            .font(.caption)
        }
        .onTapGesture(perform: onTap)
    }

    func iAmBadGuy() -> Bool {
        isMe && (claimedRole?.team == .demon || claimedRole?.team == .minion)
    }
}

#Preview {
    ZStack {
        Image("background-side")
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0)
            .edgesIgnoringSafeArea(.all)

        PlayerCircle(player: .init(seatNumber: 1, name: "Erick", claimRoleId: "secta_po", claimManual: ""), status: .init(seatNumber: 1), isMe: true, roles: [RoleDefinition(id: "secta_po", name: "Po", team: .demon)]) {
            print("tapped")
        }
    }
}
