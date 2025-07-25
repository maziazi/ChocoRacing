//
//  GameView.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 18/07/25.
//

import SwiftUI
import RealityKit
import PlayTest

struct GameView: View {
    @StateObject private var gameController = GameController()
    @StateObject private var playerController = PlayerController()
    @StateObject private var cameraController = CameraController()
    private let collisionController = CollisionController()
    
    @State private var playerEntity: Entity?
    @State private var botEntities: [Entity] = []
    @State private var collisionSubscriptions: [EventSubscription] = []
    @State private var cameraUpdateTimer: Timer?
    
    var body: some View {
        ZStack {
            VStack {
                
                RealityView { content in
                    await setupGameWorld(content: content)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    gameController.canControlPlayer ?
                    createPlayerGesture() : nil
                )
                
                VStack(spacing: 12) {
                    PlayButtonView(gameController: gameController)
                    GameControlsView(gameController: gameController)
                }
            }

            VStack {
                HStack {
                    PositionRaceIndicator(gameController: gameController)
                    PowerEffectIndicator(gameController: gameController)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                        
                Spacer()
            }
            
            CountdownView(gameController: gameController)
            LeaderboardView(gameController: gameController)
        }
        .onDisappear {
            cleanup()
        }
    }
    
    @MainActor
    private func setupGameWorld(content: any RealityViewContentProtocol) async {
        cameraController.setupCamera(content: content)
        
        if let scene = try? await Entity(named: "Scene", in: playTestBundle) {
            content.add(scene)
            
            MusicController.shared.addToScene(to: scene)
                    await MusicController.shared.ensureAllSoundsLoaded()
                    MusicController.shared.playBeforePlayMusic()

            await setupGameEntities(in: scene)
            setupControllers()
            setupCollisionDetection(content: content)
            startCameraUpdate()
        }
    }
    
    private func setupGameEntities(in scene: Entity) async {
        var foundBots: [Entity] = []
        var finishEntity: Entity?
        
        walkThroughEntities(entity: scene) { entity in
//            print("walkthrough \(entity.name)")
            if entity.name.contains("player") {
                entity.components.set(GameTagComponent(type: .player))
                toggleShieldBubbleEffect(for: entity, enable: false)
                playerEntity = entity
                cameraController.setTarget(entity)
                playerController.setPlayer(entity)
                
            } else if entity.name.contains("bot_") {
                entity.components.set(GameTagComponent(type: .bot))
                foundBots.append(entity)
                
            } else if entity.name.contains("speedUp") {
                entity.components.set(GameTagComponent(type: .speedUp))
                
            } else if entity.name.contains("powerdown") {
                entity.components.set(GameTagComponent(type: .slowDown))
                
            } else if entity.name.lowercased().contains("protection") {
                entity.components.set(GameTagComponent(type: .protection))
                
            } else if entity.name.lowercased().contains("bom") {
                entity.components.set(GameTagComponent(type: .bom))
                
            }else if entity.name.contains("obstacle") {
                entity.components.set(GameTagComponent(type: .obstacle))
                
            }else if entity.name.lowercased().contains("choco") && entity.name.lowercased().contains("fountain") {
                entity.components.set(GameTagComponent(type: .finish))
                finishEntity = entity
            }
        }
        
        botEntities = foundBots
        
       
        // Setup game with entities
        gameController.setEntities(player: playerEntity, bots: botEntities)
        
        //FCS UPDT:
//        if let player = playerEntity {
//            print("✅ masuk player")
//
//            print("📦 Mencoba load CloudChunk")
//            if let particleScene = try? await Entity(named: "CloudChunk", in: PlayTestbundle) {
//                print("✅ CloudChunk loaded")
//
//                print("🔍 Mencari entity bernama smokeParticle")
//                if let particle = particleScene.findEntity(named: "smokeParticle") {
//                    print("🎉 >>> Particle added to player")
//                    particle.position = [0, 0.5, 0]
//                    player.addChild(particle)
//                }
//            } 
//        }

        
        if let finish = finishEntity {
            gameController.setFinishEntity(finish)
        }
        
        // Apply collision to slide
        if let slide = scene.findEntity(named: "world_slide_v1_2") {
            slide.components.set(GameTagComponent(type: .slide)) // ✅ Tambahkan tag
            await applyStaticMeshCollision(to: slide)
        }
        if let slide = scene.findEntity(named: "world_slide_v1_1") {
            slide.components.set(GameTagComponent(type: .slide)) // ✅ Tambahkan tag
            await applyStaticMeshCollision(to: slide)
        }
    }
    
    private func setupControllers() {
        var config = GameConfiguration()
        config.leftBoundary = -1.5
        config.rightBoundary = 1.8
        gameController.configure(with: config)
        
        playerController.setGameController(gameController)
        playerController.setBoundaries(left: config.leftBoundary, right: config.rightBoundary)
        collisionController.setGameController(gameController)
        
        setupGameCallbacks()
    }
    
    private func setupGameCallbacks() {
        gameController.onGameStart = {
            print("🚀 Race started!")
        }
        
        gameController.onGameEnd = {
            print("🏁 Race ended!")
        }
        
        gameController.onReset = {
            self.resetPowerItems()
            self.playerController.cleanup()
        }
        
        gameController.onEffectVisualApplied = { entity, effect in
            Task {
                if effect == .shield {
                    toggleShieldBubbleEffect(for: entity, enable: true)
                }
            }
        }

        gameController.onEffectVisualRemoved = { entity, effect in
            if effect == .shield {
                toggleShieldBubbleEffect(for: entity, enable: false)
            }
        }
    }
    
    private func setupCollisionDetection(content: any RealityViewContentProtocol) {
        if let player = playerEntity {
            let playerCollision = content.subscribe(to: CollisionEvents.Began.self, on: player) { event in
                collisionController.handleCollision(event)
            }
            collisionSubscriptions.append(playerCollision)
        }
        
        for bot in botEntities {
            let botCollision = content.subscribe(to: CollisionEvents.Began.self, on: bot) { event in
                collisionController.handleCollision(event)
            }
            collisionSubscriptions.append(botCollision)
        }
    }
    
    private func startCameraUpdate() {
        cameraController.startFollowing()
        cameraUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            cameraController.updateCameraPosition()
        }
    }
    
    private func createPlayerGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                let horizontalMovement = abs(value.translation.width)
                let verticalMovement = abs(value.translation.height)
                
                if horizontalMovement > verticalMovement {
                    playerController.handleHorizontalDrag(value.translation)
                }
            }
            .onEnded { _ in
                playerController.handleDragEnd()
            }
    }
    
    private func walkThroughEntities(entity: Entity, action: (Entity) -> Void) {
        action(entity)
        for child in entity.children {
            walkThroughEntities(entity: child, action: action)
        }
    }
    
    //FCS: 
    private func resetPowerItems() {
        if let scene = playerEntity?.parent {
            walkThroughEntities(entity: scene) { entity in
                if let tagComponent = entity.components[GameTagComponent.self] {
                    if tagComponent.type == .speedUp || tagComponent.type == .slowDown || tagComponent.type == .protection || tagComponent.type == .bom || tagComponent.type == .obstacle{
                        entity.isEnabled = true
                    }
                }
            }
        }
    }
    
    private func cleanup() {
        cameraUpdateTimer?.invalidate()
        playerController.cleanup()
        gameController.cleanup()
        
        for subscription in collisionSubscriptions {
            subscription.cancel()
        }
        collisionSubscriptions.removeAll()
    }
    

    //FCS:
    func lockTranslation(for entity: Entity, lockX: Bool = true, lockY: Bool = true, lockZ: Bool = true) {
        guard var physics = entity.components[PhysicsBodyComponent.self] else {
            print("Entity does not have a PhysicsBodyComponent")
            return
        }

        physics.isTranslationLocked = (x: lockX, y: lockY, z: lockZ)
        entity.components.set(physics)
    }
    
    //ACS:
    private func toggleShieldBubbleEffect(for entity: Entity, enable: Bool) {
        if let bubble = entity.findEntity(named: "ShieldBubble") {
            bubble.isEnabled = enable
            print("🛡️ Shield bubble effect \(enable ? "enabled" : "disabled") for \(entity.name)")
        }
    }

    
    @MainActor
    private func applyStaticMeshCollision(to entity: Entity) async {
        for child in entity.children {
            if let model = child as? ModelEntity,
               let modelComponent = model.components[ModelComponent.self] {
                
                let mesh = modelComponent.mesh
                
                do {
                    let collision = try await CollisionComponent(shapes: [.generateStaticMesh(from: mesh)])
                    model.components[CollisionComponent.self] = collision
                } catch {
                    do {
                        let shape = try await ShapeResource.generateConvex(from: mesh)
                        model.components.set(CollisionComponent(shapes: [shape]))
                    } catch {
                        let bounds = model.visualBounds(relativeTo: nil)
                        let size = bounds.max - bounds.min
                        let boxShape = ShapeResource.generateBox(size: size)
                        model.components.set(CollisionComponent(shapes: [boxShape]))
                    }
                }
                
                let trackMaterial = PhysicsMaterialResource.generate(
                    friction: 0.8,
                    restitution: 0.0
                )
                
                model.components.set(PhysicsBodyComponent(
                    massProperties: .default,
                    material: trackMaterial,
                    mode: .static
                ))
            }
            await applyStaticMeshCollision(to: child)
        }
    }
}
