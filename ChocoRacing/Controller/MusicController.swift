//
//  MusicController.swift
//  ChocoRacing
//
//  Created by Lydia Mulyani on 24/07/25.
//

import RealityKit

final class MusicController {
    static let shared = MusicController()
    
    private let entity = Entity()
    
    // MARK: - Sound Resources
    private var backgroundMusic: AudioFileResource?
    private var readyGoSound: AudioFileResource?
    private var clickSound: AudioFileResource?
    private var slowdown4Sound: AudioFileResource?
    private var speedUpSound: AudioFileResource?
    private var protectionSound: AudioFileResource?
    private var boingSound: AudioFileResource?
    private var slideStoneSound: AudioFileResource?
    private var bombSound: AudioFileResource?
    
    // MARK: - Init
    private init() {
        entity.channelAudio = ChannelAudioComponent()
        loadAllSounds()
    }
    
    // MARK: - Load Sounds
    private func loadAllSounds() {
        Task {
            do {
                slowdown4Sound = try await AudioFileResource.load(named: "slowdown4", in: nil)
                backgroundMusic = try await AudioFileResource.load(named: "background", in: nil)
                readyGoSound = try await AudioFileResource.load(named: "readygo", in: nil)
                clickSound = try await AudioFileResource.load(named: "click", in: nil)
                speedUpSound = try await AudioFileResource.load(named: "speedup", in: nil)
                protectionSound = try await AudioFileResource.load(named: "pop1", in: nil)
                boingSound = try await AudioFileResource.load(named: "boing3", in: nil)
                slideStoneSound = try await AudioFileResource.load(named: "stone1", in: nil)
                bombSound = try await AudioFileResource.load(named: "splat1", in: nil)
            } catch {
                print("❌ Error loading sounds: \(error)")
            }
        }
    }
    
    func ensureAllSoundsLoaded() async {
        while backgroundMusic == nil ||
              readyGoSound == nil ||
              clickSound == nil {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func addToScene(to parent: Entity) {
        parent.addChild(entity)
    }
    
    func stopAllAudio() {
        entity.stopAllAudio()
    }

    func playBackgroundMusic() {
        guard let resource = backgroundMusic else {
            print("❌ background music not loaded")
            return
        }
        stopAllAudio()
        entity.playAudio(resource)
    }
    
    func playReadyGo() async {
        guard let resource = readyGoSound else {
            print("❌ readygo sound not loaded")
            return
        }
        stopAllAudio()
        await entity.playAudio(resource)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
    }
    
    func playReadyGoAndThenBackground() async {
        guard let readyGo = readyGoSound else {
            print("❌ readygo sound not loaded")
            return
        }
        guard let background = backgroundMusic else {
            print("❌ background music not loaded")
            return
        }
        
        entity.playAudio(readyGo)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        
        stopAllAudio()
        entity.playAudio(background)
    }

    func playslowdown4Sound() {
        guard let resource = slowdown4Sound else {
            print("❌ slowdown4 sound not loaded")
            return
        }
        entity.playAudio(resource)
    }

    func playSpeedUpSound() {
        guard let resource = speedUpSound else {
            print("❌ speed up sound not loaded")
            return
        }
        entity.playAudio(resource)
    }

    func playProtectionSound() {
        guard let resource = protectionSound else {
            print("❌ protection sound not loaded")
            return
        }
        entity.playAudio(resource)
    }

    func playObstacleSound() {
        guard let resource = boingSound else {
            print("❌ obstacle sound not loaded")
            return
        }
        entity.playAudio(resource)
    }

    func playSlideStoneSound() {
        guard let resource = slideStoneSound else {
            print("❌ stone1 sound not loaded")
            return
        }
        print("✅ stone1 sound berhasil diputar!")
        entity.playAudio(resource)
    }

    func playBombSound() {
        guard let resource = bombSound else {
            print("❌ bomb sound not loaded")
            return
        }
        entity.playAudio(resource)
    }

    func playClickSound() {
        guard let resource = clickSound else {
            print("❌ click sound not loaded")
            return
        }
        entity.playAudio(resource)
    }
}
