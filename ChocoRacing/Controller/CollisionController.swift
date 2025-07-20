//
//  CollisionController.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import RealityKit

class CollisionController {
    
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
        
        if (tA == .player || tA == .bot) && (tB == .powerup || tB == .powerdown || tB == .finish) {
            applyCollisionEffect(to: entityA, collidedWith: tB, otherEntity: entityB)
        } else if (tB == .player || tB == .bot) && (tA == .powerup || tA == .powerdown || tA == .finish) {
            applyCollisionEffect(to: entityB, collidedWith: tA, otherEntity: entityA)
        }
    }
    
    private func applyCollisionEffect(to entity: Entity, collidedWith type: GameEntityType, otherEntity: Entity) {
        guard let gameController = gameController else { return }
        
        switch type {
        case .powerup:
            gameController.applyPowerEffect(to: entity, effectType: .speedBoost, duration: 5.0)
            otherEntity.isEnabled = false
            print("⚡ Speed boost applied!")
            
        case .powerdown:
            gameController.applyPowerEffect(to: entity, effectType: .speedReduction, duration: 3.0)
            otherEntity.isEnabled = false
            print("🐌 Speed reduced!")
            
        case .finish:
            gameController.checkFinish(for: entity)
            print("🏁 Finish line reached!")
            
        default:
            break
        }
    }
}
