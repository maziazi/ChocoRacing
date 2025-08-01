//
//  CountdownView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI

struct CountdownView: View {
    @ObservedObject var gameController: GameController
    
    var body: some View {
        if gameController.isCountdownVisible {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack {
                    Image("count_\(gameController.countdownNumber)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: gameController.countdownNumber)
                    
                    Text("RACE STARTING!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 20)
                }
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: gameController.isCountdownVisible)
        }
    }
}
