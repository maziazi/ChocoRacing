//
//  MusicController.swift
//  ChocoRacing
//
//  Created by Lydia Mulyani on 22/07/25.
//
import RealityKit

final class MusicController {
    static let shared = MusicController()
    
    private let entity = Entity()
    private var backgroundMusic: AudioFileResource?
    private var beforePlayMusic: AudioFileResource?
    private var readyGoSound: AudioFileResource?
    
    private init() {
        entity.channelAudio = ChannelAudioComponent()
        loadAllSounds()
    }
    
    private func loadAllSounds() {
        Task {
            do {
                backgroundMusic = try await AudioFileResource.load(
                    named: "background",
                    in: nil,
                    inputMode: .nonSpatial,
                    loadingStrategy: .preload,
                    shouldLoop: true
                )
                
                beforePlayMusic = try await AudioFileResource.load(
                    named: "beforeplay",
                    in: nil,
                    inputMode: .nonSpatial,
                    loadingStrategy: .preload
                )
                
                readyGoSound = try await AudioFileResource.load(
                    named: "readygo",
                    in: nil,
                    inputMode: .nonSpatial,
                    loadingStrategy: .preload
                )
            } catch {
                print("❌ Error loading sounds: \(error)")
            }
        }
    }
    func ensureAllSoundsLoaded() async {
            while backgroundMusic == nil || beforePlayMusic == nil || readyGoSound == nil {
                try? await Task.sleep(nanoseconds: 100_000_000) // tunggu 0.1 detik
            }
        }
    
    func addToScene(to parent: Entity) {
        parent.addChild(entity)
    }
    
    func stopAllAudio() {
        entity.stopAllAudio()
    }
    
    func playBeforePlayMusic() {
        guard let resource = beforePlayMusic else {
            print("❌ beforeplay sound not loaded")
            return
        }
        stopAllAudio()
        entity.playAudio(resource)
    }
    
    func playBackgroundMusic() {
        guard let resource = backgroundMusic else {
            print("❌ background sound not loaded")
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
        entity.playAudio(resource)
        
        // Tunggu durasi suara readygo selesai (ubah jika perlu)
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
        
        stopAllAudio() // Stop only after readygo
        entity.playAudio(background)
    }
}
