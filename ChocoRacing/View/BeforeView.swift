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

class MenuAudioManager: ObservableObject {
    static let shared = MenuAudioManager()
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    
    private init() {}
    
    func playMenuMusic() {
        guard !isPlaying else { return }
        
        guard let soundURL = Bundle.main.url(forResource: "beforeplay", withExtension: "mp3") else {
            print("❌ beforeplay sound file not found")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            print("▶️ Playing menu music (beforeplay)")
        } catch {
            print("❌ Error playing menu music: \(error.localizedDescription)")
        }
    }
    
    func stopMenuMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        print("🔇 Stopped menu music")
    }
    
    func pauseMenuMusic() {
        audioPlayer?.pause()
        print("⏸️ Paused menu music")
    }
    
    func resumeMenuMusic() {
        audioPlayer?.play()
        print("▶️ Resumed menu music")
    }
}

struct BeforeView: View {
    @ObservedObject var gameController: GameController
    @State private var isLoadingComplete = false
    @State private var navigateToPlayButton = false
    @State private var navigateToCharacter = false
    @State private var clickPlayer: AVAudioPlayer?
    @StateObject private var menuAudio = MenuAudioManager.shared

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
                        menuAudio.stopMenuMusic() 
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
                    menuAudio.playMenuMusic()
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await preloadAssets()
            await setupMusicController()
            isLoadingComplete = true
        }
        .onAppear {
            if isLoadingComplete {
                menuAudio.playMenuMusic()
                print("🔊 BeforeView appeared - starting menu music")
            }
        }
        .onDisappear {
            if navigateToPlayButton {
                menuAudio.stopMenuMusic()
                print("🔇 BeforeView -> GameView: stopping menu music")
            } else {
                print("🎵 BeforeView -> ChangeCharacterView: keeping menu music")
            }
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
    
    private func setupMusicController() async {
        let tempParent = Entity()
        MusicController.shared.addToScene(to: tempParent)
        
        await MusicController.shared.ensureAllSoundsLoaded()
        
        print("🎵 MusicController setup completed in BeforeView")
    }
    func playClickSound() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                clickPlayer = try AVAudioPlayer(contentsOf: url)
                clickPlayer?.prepareToPlay()
                clickPlayer?.play()
            } catch {
                print("❌ Gagal memutar click: \(error.localizedDescription)")
            }
        } else {
            print("❌ File click.wav tidak ditemukan")
        }
    }
}
