//
//  PositionRaceIndicator.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 21/07/25.
//

import SwiftUI

struct PositionRaceIndicator: View {
    @ObservedObject var gameController: GameController
       
       var body: some View {
           if gameController.gameState == .playing {
               VStack(spacing: 4) {
                   Text("\(gameController.playerCurrentPosition)")
                       .font(.system(size: 48, weight: .bold, design: .rounded))
                       .foregroundColor(positionColor)
                       .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                   
                   Text(positionText)
                       .font(.caption)
                       .fontWeight(.semibold)
                       .foregroundColor(.white)
                       .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
               }
               .padding(12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(
                           LinearGradient(
                               gradient: Gradient(colors: [
                                   Color.black.opacity(0.6),
                                   Color.black.opacity(0.3)
                               ]),
                               startPoint: .top,
                               endPoint: .bottom
                           )
                       )
                       .overlay(
                           RoundedRectangle(cornerRadius: 12)
                               .stroke(positionColor.opacity(0.5), lineWidth: 2)
                       )
               )
               .scaleEffect(gameController.playerCurrentPosition == 1 ? 1.1 : 1.0)
               .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameController.playerCurrentPosition)
           }
       }
       
       private var positionColor: Color {
           switch gameController.playerCurrentPosition {
           case 1:
               return .yellow
           case 2:
               return .gray
           case 3:
               return .orange
           default:
               return .white
           }
       }
       
       private var positionText: String {
           switch gameController.playerCurrentPosition {
           case 1:
               return "1ST"
           case 2:
               return "2ND"
           case 3:
               return "3RD"
           default:
               return "\(gameController.playerCurrentPosition)TH"
           }
       }
}
