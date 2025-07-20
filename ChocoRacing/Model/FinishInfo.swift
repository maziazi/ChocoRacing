//
//  FinishInfo.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import Foundation

struct FinishInfo {
    let entityName: String
    let finishTime: Date
    let position: Int
    
    var isPlayer: Bool {
        return entityName.contains("player")
    }
    
    var displayName: String {
        if isPlayer {
            return "🎯 Player"
        } else {
            return "🤖 \(entityName.capitalized)"
        }
    }
}
