//
//  RacingEntity.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import RealityKit

struct RacingEntity {
    let entity: Entity
    let name: String
    let type: GameEntityType
    var isFinished: Bool = false
    var powerEffect: PowerEffectType = .none
    var powerEffectTimeRemaining: Double = 0.0
    var originalSpeed: Float = 2.0
    
    var startingPosition: SIMD3<Float>
    var startingOrientation: simd_quatf
    
    var displayName: String {
        switch type {
        case .player:
            return "🎯 Player"
        case .bot:
            if let botNumber = name.components(separatedBy: "_").last {
                return "🤖 Bot \(botNumber)"
            }
            return "🤖 Bot"
        default:
            return name.capitalized
        }
    }
}
