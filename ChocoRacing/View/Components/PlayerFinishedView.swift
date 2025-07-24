//
//  PlayerFinishedView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 21/07/25.
//

import SwiftUI

struct PlayerFinishedView: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.showPlayerFinished {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.3).repeatForever(autoreverses: true), value: gameController.showPlayerFinished)
                    
                    Text("YOU ARE FINISH!")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .multilineTextAlignment(.center)
                    
                    Text("Position: \(getPositionText())")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(getPositionColor())
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .opacity(0.8)
                                .scaleEffect(0.8)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.3)
                                    .delay(Double(index) * 0.1)
                                    .repeatForever(autoreverses: true),
                                    value: gameController.showPlayerFinished
                                )
                        }
                    }
                    .padding(.top, 10)
                }
                .scaleEffect(gameController.showPlayerFinished ? 1.0 : 0.5)
                .opacity(gameController.showPlayerFinished ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: gameController.showPlayerFinished)
            }
        }
    }
    
    // ✅ GUNAKAN POSISI FINAL YANG TERSIMPAN
    private func getPositionText() -> String {
        let finalPosition = gameController.playerFinalPosition
        switch finalPosition {
        case 1:
            return "🥇 1ST PLACE!"
        case 2:
            return "🥈 2ND PLACE!"
        case 3:
            return "🥉 3RD PLACE!"
        case 4:
            return "🏃 4TH PLACE!"
        case 5:
            return "🏃 5TH PLACE!"
        default:
            return "🏃 \(finalPosition)TH PLACE!"
        }
    }
    
    private func getPositionColor() -> Color {
        let finalPosition = gameController.playerFinalPosition
        switch finalPosition {
        case 1:
            return .yellow
        case 2:
            return .gray
        case 3:
            return .orange
        case 4, 5:
            return .white
        default:
            return .white
        }
    }
}
