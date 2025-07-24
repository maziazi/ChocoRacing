//
//  BeforePage.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 18/07/25.
//

import SwiftUI
import RealityKit
import PlayTest

struct BeforeView: View {
    @ObservedObject var gameController: GameController
    @State private var isLoadingComplete = false
    @State private var navigateToPlayButton = false
    @State private var navigateToCharacter = false

    var body: some View {
        ZStack {
            if isLoadingComplete {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 450, height: 400)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)

                    Spacer().frame(height: 90)

                    // NavigationLink to PlayButtonScreen
                    NavigationLink(destination: GameView(gameController: gameController), isActive: $navigateToPlayButton) {
                        EmptyView()
                    }

                    Button(action: {
                        navigateToPlayButton = true
                    }) {
                        Image("button_play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 90)
                    }

                    // NavigationLink to ChangeCharacterView
                    NavigationLink(destination: ChangeCharacterView(), isActive: $navigateToCharacter) {
                        EmptyView()
                    }

                    Button(action: {
                        navigateToCharacter = true
                    }) {
                        Image("button_changeCharacter")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 264, height: 94)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SplashView {
                    isLoadingComplete = true
                }
            }
        }
        .task {
            await preloadAssets()
            isLoadingComplete = true
        }
    }

    func preloadAssets() async {
            let assetNames = [
                "CloudChunk", "Floor", "Mangkok", "PillBottle", "PLETES_Plan B_1",
                "Scene", "Skull", "SkyDome", "Slide", "SlideNCream",
                "smores", "ToyCar", "world_slide_v1"
            ]

            for name in assetNames {
                do {
                    _ = try await Entity.load(named: name, in: playTestBundle)
                    print("✅ Loaded: \(name)")
                } catch {
                    print("❌ Failed to load: \(name) — \(error.localizedDescription)")
                }
            }
        }
    }
