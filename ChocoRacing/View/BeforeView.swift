//
//  BeforePage.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 18/07/25.
//

import SwiftUI
import RealityKit
import PlayTest
import AVFoundation

struct BeforeView: View {
    @ObservedObject var gameController: GameController
    @State private var isLoadingComplete = false
    @State private var navigateToPlayButton = false
    @State private var navigateToCharacter = false
    @State private var audioPlayer: AVAudioPlayer?

    var body: some View {
        ZStack {
            if isLoadingComplete {
                ZStack {
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .clipped()

                    Image("background_beforeView")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .clipped()
                }

                VStack(spacing: 5) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 290, height: 240)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .padding(.top, 130)
                        .padding(.bottom, 150)

                    NavigationLink(destination: GameView(gameController: gameController), isActive: $navigateToPlayButton) {
                        EmptyView()
                    }
                    Button(action: {
                        playClickSound()
                        navigateToPlayButton = true
                    }) {
                        Image("Button_Play")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 70)
                    }

                    NavigationLink(destination: ChangeCharacterView(), isActive: $navigateToCharacter) {
                        EmptyView()
                    }
                    Button(action: {
                        playClickSound()
                        navigateToCharacter = true
                    }) {
                        Image("button_changeCharacter")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 210, height: 72)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SplashView {
                    isLoadingComplete = true
                    playIntroSound()
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await preloadAssets()
            isLoadingComplete = true
        }
    }
    func playIntroSound() {
        guard let soundURL = Bundle.main.url(forResource: "beforeplay", withExtension: "mp3") else {
            print("❌ beforeplay sound file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("▶️ Playing beforeplay sound")
        } catch {
            print("❌ Error playing beforeplay sound: \(error.localizedDescription)")
        }
    }
    func playClickSound() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("❌ Failed to play click sound: \(error.localizedDescription)")
            }
        } else {
            print("❌ click.mp3 not found in bundle")
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
