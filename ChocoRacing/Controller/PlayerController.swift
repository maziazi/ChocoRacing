//
//  PlayerController.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI
import RealityKit

class PlayerController: ObservableObject {
    
    @Published var maxLeftDistance: Float = -1.65
    @Published var maxRightDistance: Float = 2.2
    @Published var sensitivity: Float = 0.02
    @Published var responsiveness: Float = 0.15
    @Published var returnSpeed: Float = 0.1
    
    private weak var playerEntity: Entity?
    private weak var gameController: GameController?
    private var targetHorizontalVelocity: Float = 0.0
    var isDragging = false
    private var returnToZeroTimer: Timer?
    
    func setPlayer(_ entity: Entity) {
        self.playerEntity = entity
        print("🎮 Player controller setup for: \(entity.name)")
    }
    
    func setGameController(_ controller: GameController) {
        self.gameController = controller
    }
    
    func setBoundaries(left: Float, right: Float) {
        maxLeftDistance = left
        maxRightDistance = right
    }
    
    func handleHorizontalDrag(_ translation: CGSize) {
        guard let gameController = gameController,
              gameController.canControlPlayer,
              let player = playerEntity else { return }
        
        isDragging = true
        stopReturnToZero()
        
        let deltaX = Float(translation.width) * sensitivity
        let currentX = player.position.x
        
        var targetVelocity = deltaX * 14.0
        
        // Apply boundary resistance
        if currentX <= maxLeftDistance && targetVelocity < 0 {
            targetVelocity *= 0.1
        } else if currentX >= maxRightDistance && targetVelocity > 0 {
            targetVelocity *= 0.1
        }
        
        targetHorizontalVelocity = max(-2.5, min(2.5, targetVelocity))
        gameController.applyPlayerHorizontalMovement(targetHorizontalVelocity)
    }
    
    func handleDragStart() {
        guard gameController?.canControlPlayer == true else { return }
        isDragging = true
        stopReturnToZero()
    }
    
    func handleDragEnd() {
        isDragging = false
        startReturnToZero()
    }
    
    private func startReturnToZero() {
        returnToZeroTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.updateReturnToZero()
        }
    }
    
    private func stopReturnToZero() {
        returnToZeroTimer?.invalidate()
        returnToZeroTimer = nil
    }
    
    private func updateReturnToZero() {
        guard !isDragging,
              let gameController = gameController,
              gameController.canControlPlayer else {
            stopReturnToZero()
            return
        }
        
        targetHorizontalVelocity *= (1.0 - returnSpeed)
        
        if abs(targetHorizontalVelocity) < 0.01 {
            targetHorizontalVelocity = 0.0
            stopReturnToZero()
        }
        
        gameController.applyPlayerHorizontalMovement(targetHorizontalVelocity)
    }
    
    func cleanup() {
        stopReturnToZero()
        targetHorizontalVelocity = 0.0
        isDragging = false
    }
}
