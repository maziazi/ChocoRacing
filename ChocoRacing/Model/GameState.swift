//
//  GameState.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import Foundation

enum GameState {
    case waiting    // Waiting for player to start
    case countdown  // Countdown 3-2-1
    case playing    // Game is running
    case paused     // Game is paused
    case finished   // Game is over
}
