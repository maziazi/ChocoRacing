//
//  PlayButtonView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct PlayButtonView: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.showPlayButton {
            Button(action: {
                gameController.startGame()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("START RACE")
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .scaleEffect(gameController.gameState == .waiting ? 1.0 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: gameController.gameState)
        }
    }
}
