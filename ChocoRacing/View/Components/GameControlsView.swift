//
//  GameControlsView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct GameControlsView: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        HStack(spacing: 16) {
            if gameController.gameState == .playing {
                Button("⏸️ Pause") {
                    MusicController.shared.playClickSound()
                    gameController.pauseGame()
                }
                .buttonStyle(.bordered)
            } else if gameController.gameState == .paused {
                Button("▶️ Resume") {
                    MusicController.shared.playClickSound()
                    gameController.resumeGame()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if gameController.gameState != .waiting {
                Button("🔄 Reset Race") {
                    MusicController.shared.playClickSound()
                    gameController.resetGame()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
            }
            
            if gameController.gameState == .playing || gameController.gameState == .paused {
                Button("🏁 End Race") {
                    MusicController.shared.playClickSound()
                    gameController.endGame()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
