//
//  LeaderboardView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI
import simd
import AVFoundation

struct LeaderboardView: View {
    @ObservedObject var gameController: GameController
    @State private var stableResults: [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] = []
    @Environment(\.presentationMode) var presentationMode
    @State private var clickPlayer: AVAudioPlayer?
    @State private var hasPlayedResultSound = false
    
    var body: some View {
        if gameController.showLeaderboard && !gameController.finishedEntities.isEmpty {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack{
                    ZStack{
                        HStack {
                            Image("Leaderboard_1")
                                .resizable()
                                .frame(width: 380, height: 500)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(Array(stableResults.prefix(4).enumerated()), id: \.element.entityName) { index, result in
                                HStack {
                                    getPositionEmoji(result.finalPosition)
                                    
                                    Text(result.displayName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(result.isPlayer ? .yellow : .black)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(result.isPlayer ? Color.black.opacity(1) : Color.white.opacity(1))
                                )
                            }
                        }
                        .frame(maxWidth: 200)
                        .offset(y: 10)
                    }
                    Button(action: {
                        playClickSound()
                        gameController.restartGame()
                    }){
                        HStack {
                            Image("button_playAgain")
                                .resizable()
                                .frame(width: 150, height: 60)
                        }
                    }
                    .offset(y: -60)
                    
                    Button(action: {
                        playClickSound()
                        gameController.resetGame()
                        presentationMode.wrappedValue.dismiss()
                    }){
                        HStack {
                            Image("button_home")
                                .resizable()
                                .frame(width: 150, height: 60)
                        }
                    }
                    .offset(y: -60)
                }
                .padding()
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.5), value: gameController.showLeaderboard)
            .onAppear {
                stableResults = getStableRaceResults()
                if !hasPlayedResultSound {
                    playResultSound()
                    hasPlayedResultSound = true
                }
            }
        }
    }
    
    private func playResultSound() {
            if let playerResult = stableResults.first(where: { $0.isPlayer }) {
                let playerPosition = playerResult.finalPosition
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if playerPosition <= 3 {
                        MusicController.shared.playWinSound()
                        print("🎉 Player menang! Posisi: \(playerPosition)")
                    } else {
                        MusicController.shared.playLoseSound()
                        print("😞 Player kalah! Posisi: \(playerPosition)")
                    }
                }
            }
        }
        
    private func getPositionEmoji(_ position: Int) -> AnyView {
        switch position {
        case 1:
            return AnyView(
                Image("badge_first")
                    .resizable()
                    .frame(width: 26, height: 36)
            )
        case 2:
            return AnyView(
                Image("badge_second")
                    .resizable()
                    .frame(width: 26, height: 36)
            )
        case 3:
            return AnyView(
                Image("badge_third")
                    .resizable()
                    .frame(width: 26, height: 36)
            )
        case 4:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .frame(width: 26, height: 36)
            )
        default:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .frame(width: 0, height: 0)
            )
        }
    }
    
    private func getStableRaceResults() -> [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] {
        var results: [(entityName: String, displayName: String, finalPosition: Int, isPlayer: Bool, isFinished: Bool)] = []
        
        guard let finishEntity = gameController.finishEntity else { return results }
        
        var entityDistances: [(entityName: String, displayName: String, distance: Float, isPlayer: Bool, isFinished: Bool)] = []
        
        for (entityName, racingEntity) in gameController.racingEntities {
            let isPlayer = (entityName == "player")
            let isFinished = gameController.finishedEntities.contains { $0.entityName == entityName }
            let distance = simd_distance(racingEntity.entity.position, finishEntity.position)
            
            let displayName = isPlayer ? "Player" : "Bot \(entityName.replacingOccurrences(of: "bot_", with: ""))"
            
            entityDistances.append((
                entityName: entityName,
                displayName: displayName,
                distance: distance,
                isPlayer: isPlayer,
                isFinished: isFinished
            ))
        }
        
        entityDistances.sort { entity1, entity2 in
            if entity1.isFinished && entity2.isFinished {
                let index1 = gameController.finishedEntities.firstIndex { $0.entityName == entity1.entityName } ?? 999
                let index2 = gameController.finishedEntities.firstIndex { $0.entityName == entity2.entityName } ?? 999
                return index1 < index2
            } else if entity1.isFinished && !entity2.isFinished {
                return true // Finished entities di depan
            } else if !entity1.isFinished && entity2.isFinished {
                return false // Unfinished entities di belakang
            } else {
                return entity1.distance < entity2.distance
            }
        }
        
        for (index, entityInfo) in entityDistances.enumerated() {
            let finalPosition = min(index + 1, 4)
            
            results.append((
                entityName: entityInfo.entityName,
                displayName: entityInfo.displayName,
                finalPosition: finalPosition,
                isPlayer: entityInfo.isPlayer,
                isFinished: entityInfo.isFinished
            ))
        }
        
        return results
    }
    
    func playClickSound() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                clickPlayer = try AVAudioPlayer(contentsOf: url)
                clickPlayer?.prepareToPlay()
                clickPlayer?.play()
            } catch {
                print("❌ Gagal memutar click: \(error.localizedDescription)")
            }
        } else {
            print("❌ File click.mp3 tidak ditemukan")
        }
    }
}

