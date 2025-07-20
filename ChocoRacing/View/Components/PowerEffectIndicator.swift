//
//  PowerEffectIndicator.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct PowerEffectIndicator: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.currentPowerEffect != .none {
            HStack(spacing: 8) {
                effectIcon
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(effectText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(effectColor)
                    
                    Text("\(String(format: "%.1f", gameController.powerEffectTimeRemaining))s remaining")
                        .font(.caption)
                        .foregroundColor(effectColor.opacity(0.8))
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(effectColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(effectColor, lineWidth: 2)
                    )
            )
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameController.currentPowerEffect)
        }
    }
    
    private var effectIcon: some View {
        Group {
            switch gameController.currentPowerEffect {
            case .speedBoost:
                Image(systemName: "bolt.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            case .speedReduction:
                Image(systemName: "tortoise.fill")
                    .font(.title)
                    .foregroundColor(.orange)
            case .none:
                EmptyView()
            }
        }
    }
    
    private var effectText: String {
        switch gameController.currentPowerEffect {
        case .speedBoost:
            return "SPEED BOOST!"
        case .speedReduction:
            return "SLOWED DOWN!"
        case .none:
            return ""
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
