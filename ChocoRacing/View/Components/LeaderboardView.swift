//
//  LeaderboardView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.showLeaderboard && !gameController.finishedEntities.isEmpty {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("🏁 RACE RESULTS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(gameController.finishedEntities.enumerated()), id: \.element.entityName) { index, finishInfo in
                            HStack {
                                Text(getPositionEmoji(finishInfo.position))
                                    .font(.title)
                                
                                Text("\(finishInfo.position).")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Text(finishInfo.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(finishInfo.isPlayer ? .yellow : .white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(finishInfo.isPlayer ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.3))
                    )
                    
                    Button("🔄 Play Again") {
                        gameController.resetGame()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding()
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.5), value: gameController.showLeaderboard)
        }
    }
    
    private func getPositionEmoji(_ position: Int) -> String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏃"
        }
    }
}

