//
//  PositionRaceIndicator.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 21/07/25.
//

import SwiftUI

struct PositionRaceIndicator: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.gameState == .playing || gameController.gameState == .paused {
            VStack(spacing: 4) {
                getPositionBadge(gameController.playerCurrentPosition)
            }
            .padding(8)
        }
    }
    
    private func getPositionBadge(_ position: Int) -> some View {
        switch position {
        case 1:
            return AnyView(
                Image("badge_first")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 55)  // Sedikit lebih besar untuk visibility
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        case 2:
            return AnyView(
                Image("badge_second")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 55)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        case 3:
            return AnyView(
                Image("badge_third")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 55)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            )
        case 4:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 71)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: -3, y: -10)
            )
        default:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 71)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: -3, y: -10)
            )
        }
    }
}
