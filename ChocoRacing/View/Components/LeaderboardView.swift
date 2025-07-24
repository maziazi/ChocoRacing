//
//  LeaderboardView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var gameController: GameController
    @State private var stableResults: [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] = []
    
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
                        ForEach(Array(stableResults.prefix(5).enumerated()), id: \.element.entityName) { index, result in
                            HStack {
                                Text(getPositionEmoji(result.finalPosition))
                                    .font(.title)
                                
                                Text("\(result.finalPosition).")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Text(result.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(result.isPlayer ? .yellow : .white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(result.isPlayer ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
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
            .onAppear {
                stableResults = getStableRaceResults()
            }
        }
    }
    
    private func getPositionEmoji(_ position: Int) -> String {
        switch position {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        case 4, 5: return "🏃"
        default: return "🏃"
        }
    }
    
    private func getStableRaceResults() -> [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] {
        var results: [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] = []
        
        let allPositions = gameController.getAllEntityPositions()
        
        for (entityName, _) in gameController.racingEntities {
            let isPlayer = (entityName == "player")
            let isFinished = gameController.finishedEntities.contains { $0.entityName == entityName }
            
            let finalPosition: Int
            if isPlayer {
                finalPosition = gameController.playerFinalPosition
            } else {
                finalPosition = allPositions[entityName] ?? 5
            }
            
            let displayName = isPlayer ? "Player" : "Bot \(entityName.replacingOccurrences(of: "bot_", with: ""))"
            
            results.append((
                entityName: entityName,
                displayName: displayName,
                finalPosition: finalPosition,
                isPlayer: isPlayer,
                isFinished: isFinished
            ))
        }
        
        results.sort { $0.finalPosition < $1.finalPosition }
        
        return results
    }
}


