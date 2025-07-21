//
//  PowerEffectIndicator.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct PowerEffectIndicator: View {
    @ObservedObject var gameController: GameController
    
    private var progress: Double {
        guard gameController.currentPowerEffect != .none else { return 0.0 }
        
        let maxDuration: Double
        switch gameController.currentPowerEffect {
        case .speedBoost:
            maxDuration = 5.0
        case .speedReduction:
            maxDuration = 3.0
        case .none:
            maxDuration = 1.0
        }
        
        return gameController.powerEffectTimeRemaining / maxDuration
    }
    
    var body: some View {
        if gameController.currentPowerEffect != .none {
            HStack(spacing: 8) {
                // Circle Timer
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.black.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    // Progress circle (countdown from full to empty)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            effectColor,
                            style: StrokeStyle(
                                lineWidth: 6,
                                lineCap: .round
                            )
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Center icon
                    effectIcon
                        .font(.title3)
                        .foregroundColor(effectColor)
                }
                
                Spacer()
            }
            .padding()
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameController.currentPowerEffect)
        }
    }
    
    private var effectIcon: some View {
        Group {
            switch gameController.currentPowerEffect {
            case .speedBoost:
                Image(systemName: "bolt.fill")
            case .speedReduction:
                Image(systemName: "tortoise.fill")
            case .none:
                EmptyView()
            }
        }
    }
    
    private var effectColor: Color {
        switch gameController.currentPowerEffect {
        case .speedBoost:
            return .yellow
        case .speedReduction:
            return .orange
        case .none:
            return .clear
        }
    }
}
