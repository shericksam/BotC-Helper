//
//  PlayerCircle.swift
//  BotC Helper
//
//  Created by Erick Samuel Guerrero Arreola on 03/12/25.
//

import SwiftUI
import SwiftData

struct PlayerCircle: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
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
                    .strokeBorder(
                        isMe ? Color.green : (status.dead ? Color.purple : Color.primaryBrown),
                        lineWidth: isRegular ? 5 : 3
                    )
                    .frame(width: circleSize, height: circleSize)
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
                            .font(nameFont)
                            .lineLimit(isRegular ? 4 : 3)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("#\(player.seatNumber)")
                            .foregroundColor(.black)
                            .font(seatFont)
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
                // Muerto — icon varies by death type
                if status.dead {
                    deathIcon(for: status.deathType)
                }
                // Rol asignado (opcional)
                if let role = claimedRole, !iAmBadGuy() {
                        RolIcon(name: role.id)
                            .frame(height: rolIconSize)
                            .clipShape(Circle())
                            .offset(x: 0, y: rolIconOffsetY)
                }
            }
            Group {
                if let role = claimedRole, !iAmBadGuy() {
                    Text(role.nameLocalized())
                } else {
                    Text(MSG("new_game_seat_picker", player.seatNumber))
                }
            }
            .foregroundColor(.white)
            .font(footerFont)
        }
        .onTapGesture(perform: onTap)
    }

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var circleSize: CGFloat {
        isRegular ? 110 : 78
    }

    private var rolIconOffsetY: CGFloat {
        isRegular ? -44 : -32
    }

    private var rolIconSize: CGFloat {
        isRegular ? 110 : 78
    }

    private var nameFont: Font {
        isRegular ? .title2 : .system(size: 12, weight: .semibold)
    }

    private var seatFont: Font {
        isRegular ? .title2 : .system(size: 14, weight: .bold)
    }

    private var footerFont: Font {
        isRegular ? .body : .system(size: 11, weight: .medium)
    }


    func iAmBadGuy() -> Bool {
        isMe && (claimedRole?.team == .demon || claimedRole?.team == .minion)
    }

    @ViewBuilder
    private func deathIcon(for type: String?) -> some View {
        switch type {
        case "nightKill":
            Image(systemName: "moon.fill")
                .font(.largeTitle)
                .foregroundColor(.purple)
        case "execution":
            Image(systemName: "person.fill.xmark")
                .font(.largeTitle)
                .foregroundColor(.orange)
        default:
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ZStack {
        Image("background-side")
            .resizable()
            .scaledToFill()
            .frame(minWidth: 0)
            .edgesIgnoringSafeArea(.all)
        let player = Player(seatNumber: 1, name: "Erick", claimRoleId: "grandmother", claimManual: "")
        let status = player.statuses.first ?? .init(dayIndex: 0)
        PlayerCircle(player: player, status: status, isMe: true, roles: rolesExample) {
            print("tapped")
        }
    }
}
