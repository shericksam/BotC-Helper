//
//  PlayerCircle.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI

struct PlayerCircle: View {
    var player: Player
    var status: PlayerStatusPerDay
    var isMe: Bool
    var onTap: () -> Void

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .strokeBorder(isMe ? Color.green : (status.dead ? .red : Color.primaryBrown), lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .overlay(
                        VStack {
                            if !player.name.isEmpty {
                                Text(player.name)
                                    .foregroundColor(.black)
                                    .font(.caption)
                                    .lineLimit(3)
                            } else {
                                Text(!player.name.isEmpty ? player.initials : "#\(player.seatNumber)")
                                    .foregroundColor(.black)
                                    .font(.headline)
                            }
                        }
                    )
                    .background(
                        Image("background")
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    )
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
            }
            Text("Seat \(player.seatNumber)")
                .foregroundColor(.white)
                .font(.caption)
        }
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    ZStack {
        Image("background-side")
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0)
            .edgesIgnoringSafeArea(.all)

        PlayerCircle(player: .init(seatNumber: 1, name: "Erick", claim: ""), status: .init(seatNumber: 1), isMe: true) {
            print("tapped")
        }
    }
}
