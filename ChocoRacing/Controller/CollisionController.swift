//
//  GameController.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import RealityKit
import SwiftUI

class CollisionController {
    let entityTypes: [GameEntityType] = [.speedUp, .slowDown, .protection, .bom, .finish, .obstacle, .slide]
    
    private var oneSec: Bool = false
    private var oneSec2: Bool = false
    
    private weak var gameController: GameController?
    
    func setGameController(_ controller: GameController) {
        self.gameController = controller
    }
    
    func handleCollision(_ event: CollisionEvents.Began) {
        guard let gameController = gameController,
              gameController.gameState == .playing else { return }
        
        let entityA = event.entityA
        let entityB = event.entityB
        
        let typeA = entityA.components[GameTagComponent.self]?.type
        let typeB = entityB.components[GameTagComponent.self]?.type
        
        guard let tA = typeA, let tB = typeB else { return }
        
        // Check if entity A or B is player or bot, and if the other entity is in entityTypes
        if (tA == .player || tA == .bot), entityTypes.contains(tB) {
            applyCollisionEffect(to: entityA, collidedWith: tB, otherEntity: entityB)
        }
    }
    
    
    
    private func applyCollisionEffect(to entity: Entity, collidedWith type: GameEntityType, otherEntity: Entity) {
        guard let gameController = gameController else { return }
        
        switch type {
        case .speedUp:
            gameController.applyPowerEffect(to: entity, effectType: .speedBoost, duration: 5.0)
            otherEntity.isEnabled = false
            if gameController.getEntityName(entity) == "player" {
                MusicController.shared.playSpeedUpSound()
            }
            
            print("⚡ Speed boost applied!")
            
        case .slowDown:
            gameController.applyPowerEffect(to: entity, effectType: .speedReduction, duration: 3.0)
            otherEntity.isEnabled = false
            if gameController.getEntityName(entity) == "player" {
                MusicController.shared.playslowdown4Sound()
            }
            print("🐌 Speed reduced!")
            
        case .protection:
            gameController.applyPowerEffect(to: entity, effectType: .shield, duration: 5.0)
            otherEntity.isEnabled = false
            if gameController.getEntityName(entity) == "player" {
                MusicController.shared.playProtectionSound()
            }
            print("🛡️ Protection activated!")
            
        case .bom:
            gameController.applyPowerEffect(to: entity, effectType: .splash, duration: 3.0)
            otherEntity.isEnabled = false
            if gameController.getEntityName(entity) == "player" {
                MusicController.shared.playBombSound()
            }
            print("💥 Bomb exploded!")
            
        case .finish:
            print("🏁 Finish line reached!")
        
        case .obstacle:
            gameController.handleObstacleCollision(entity: entity, otherEntity: otherEntity)
            if gameController.getEntityName(entity) == "player" && gameController.currentPowerEffect != .shield {
                   MusicController.shared.playObstacleSound()
               }
               print("💥 Obstacle hit!")
        default:
            print("masuk default di collisionControl")

        }
    }
}
