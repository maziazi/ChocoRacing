//
//  ProgressRaceIndicator.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 21/07/25.
//

import SwiftUI

struct ProgressRaceIndicator: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.gameState == .playing || gameController.gameState == .paused {
            VStack(spacing: 8) {
                HStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue,
                                            Color.green,
                                            Color.yellow,
                                            Color.orange
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * CGFloat(gameController.playerProgress),
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.3), value: gameController.playerProgress)
                            .frame(width: max(16, geometry.size.width * CGFloat(gameController.playerProgress)))
                        }
                    }
                    .frame(height: 8)
                }
                
                Text("\(Int(gameController.playerProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                
                if gameController.playerDistanceToFinish > 0 {
                    Text("Distance: \(String(format: "%.1f", gameController.playerDistanceToFinish))m")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.7),
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}
