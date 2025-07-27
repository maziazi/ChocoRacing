//
//  LeaderboardView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI
import simd
import AVFoundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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
                                    HStack {
                                        getPositionEmoji(result.finalPosition)
                                                                            
                                        if result.finalPosition == 4 {
                                            Spacer()
                                                .frame(width: 5)
                                        }
                                    }
                                    .frame(width: 35, alignment: .leading)
                                    
                                    Text(result.displayName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(result.isPlayer ? Color(hex: "#EB5F4D") : Color(hex: "#A25E3B"))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(result.isPlayer ? Color(hex: "#FAE392") : Color(hex: "#F6CD9B"))
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
            .onDisappear {
                hasPlayedResultSound = false
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
                    .scaledToFit()
                    .frame(width: 30, height: 40)
                    .clipped()
            )
        case 2:
            return AnyView(
                Image("badge_second")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 40)
                    .clipped()
            )
        case 3:
            return AnyView(
                Image("badge_third")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 40)
                    .clipped()
            )
        case 4:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 28)
                    .clipped()
                    .offset(y: 3)
            )
        default:
            return AnyView(
                Image("badge_fourth")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 28)
                    .clipped()
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
            print("❌ File click.wav tidak ditemukan")
        }
    }
}
