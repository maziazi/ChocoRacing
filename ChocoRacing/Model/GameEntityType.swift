//
//  GameEntityType.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import Foundation

enum GameEntityType: UInt8, Codable {
    case player
    case bot
    case powerup
    case powerdown
    case finish
    case start
}
