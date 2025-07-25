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
                Text("\(gameController.playerCurrentPosition)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(getPositionSuffix())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(getPositionColor().opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private func getPositionSuffix() -> String {
        let position = gameController.playerCurrentPosition
        switch position {
        case 1: return "1ST"
        case 2: return "2ND"
        case 3: return "3RD"
        case 4: return "4TH"
        default: return "4TH"
        }
    }
    
    private func getPositionColor() -> Color {
        let position = gameController.playerCurrentPosition
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        case 4: return .red
        default: return .red
        }
    }
}
