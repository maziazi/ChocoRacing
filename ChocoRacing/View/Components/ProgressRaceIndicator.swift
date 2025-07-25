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
            ZStack() {
                Image("progressBar")
                    .resizable()
                    .frame(width: 250, height: 60)
                    .offset(x: 7, y: -10)
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
                                            Color.orange,
                                            Color.pink
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
                    .frame(width: 200, height: 8)
                    .offset(x: 6, y:-3)
                }
            }
            .padding(12)
        }
    }
}
