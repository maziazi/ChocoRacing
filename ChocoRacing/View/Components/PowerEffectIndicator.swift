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
            case .shield:
                maxDuration = 5.0 // Or whatever duration you choose for the shield
            case .splash:
                maxDuration = 3.0 // Or whatever duration you choose for the splash
            case .none:
                maxDuration = 1.0
        }
        
        return gameController.powerEffectTimeRemaining / maxDuration
    }
    
    var body: some View {
        if gameController.currentPowerEffect != .none {
            HStack(spacing: 8) {
                ZStack {
                    Image("indicator")
                        .resizable()
                        .frame(width: 60, height: 60)
                    
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
                Image("powerUp_speedUp")
                    .resizable()
                    .frame(width: 32, height: 32)
            case .speedReduction:
                Image("powerDown_slowDown")
                    .resizable()
                    .frame(width: 32, height: 32)
            case .shield:
                Image("powerUp_protection")
                    .resizable()
                    .frame(width: 32, height: 32)
            case .splash:
                Image("powerDown_bomb")
                    .resizable()
                    .frame(width: 32, height: 32)
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
        case .shield:
            return .blue
        case .splash:
            return .red
        case .none:
            return .clear
        }
    }
}
