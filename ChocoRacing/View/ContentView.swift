//
//  ContentView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 18/07/25.
//

import SwiftUI
import PlayTest

struct ContentView: View {
    @StateObject private var gameController = GameController()
    @State private var isLoadingComplete = false

    var body: some View {
        NavigationStack {
            if isLoadingComplete {
                BeforeView(gameController: gameController)
            } else {
                SplashView {
                    isLoadingComplete = true
                }
            }
        }
    }
}
