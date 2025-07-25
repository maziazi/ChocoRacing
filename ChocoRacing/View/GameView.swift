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
            }
            
            VStack {
                HStack(alignment: .top, spacing: 0) {
                    PositionRaceIndicator(gameController: gameController)
                        .frame(width: 45, alignment: .leading)
                        .offset(x: -30)
                    
                    ProgressRaceIndicator(gameController: gameController)
                        .frame(width: 250, alignment: .center)
                        .offset(x: -30)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 40, height: 1)
                        
                        PowerEffectIndicator(gameController: gameController)
                            .frame(width: 40, alignment: .center)
                            .offset(y: -10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center) 
                .padding(.horizontal, 16)
                .padding(.top, 50)
                .offset(x: 10)
                
                Spacer()
            }
            VStack(spacing: 12) {
                Spacer()
                VStack() {
                    PlayButtonView(gameController: gameController)
                    GameControlsView(gameController: gameController)
                }
                .padding(.bottom, 16)
            }
            
            PlayerFinishedView(gameController: gameController)
            
            CountdownView(gameController: gameController)
            LeaderboardView(gameController: gameController)
        }
        .onDisappear {
            cleanup()
        }
        .ignoresSafeArea(.all, edges: [.top, .bottom])
    }
    
    @MainActor
    private func setupGameWorld(content: any RealityViewContentProtocol) async {
        cameraController.setupCamera(content: content)
        
        if let scene = try? await Entity(named: "Scene", in: playTestBundle) {
            content.add(scene)
            await setupGameEntities(in: scene)
            setupControllers()
            setupCollisionDetection(content: content)
            startCameraUpdate()
        }
    }
    
    private func setupGameEntities(in scene: Entity) async {
        var foundBots: [Entity] = []
        var finishEntity: Entity?
        var startEntity: Entity?
        
            walkThroughEntities(entity: scene) { entity in
            if entity.name.contains("player") {
                entity.components.set(GameTagComponent(type: .player))
                playerEntity = entity
                cameraController.setTarget(entity)
                playerController.setPlayer(entity)
                
            } else if entity.name.contains("bot") {
                entity.components.set(GameTagComponent(type: .bot))
                foundBots.append(entity)
                
            } else if entity.name.contains("powerup") {
                entity.components.set(GameTagComponent(type: .powerup))
                
            } else if entity.name.contains("powerdown") {
                entity.components.set(GameTagComponent(type: .powerdown))
            }
        }
        
        if let envSlide = scene.findEntity(named: "PillBottle") {
                    finishEntity = envSlide
            }
            
        
        botEntities = foundBots
        
        gameController.setEntities(player: playerEntity, bots: botEntities)
        
        if let player = playerEntity {
            let startLine = Entity()
            startLine.position = player.position
            startLine.name = "virtual_start_line"
            gameController.setStartLineEntity(startLine)
            print("🏁 Virtual start line created at: \(player.position)")
        }
        
        if let finish = finishEntity {
            gameController.setFinishEntity(finish)
        }
        
        if let slide = scene.findEntity(named: "enviroment_slide") {
            await applyStaticMeshCollision(to: slide)
        }
        if let slide = scene.findEntity(named: "world_slide_v1_1") {
            await applyStaticMeshCollision(to: slide)
        }
    }
    
    private func setupControllers() {
        var config = GameConfiguration()
        config.leftBoundary = -1.65
        config.rightBoundary = 2.2
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
        cameraUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.00000064, repeats: true) { _ in
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
    
    private func resetPowerItems() {
        if let scene = playerEntity?.parent {
            walkThroughEntities(entity: scene) { entity in
                if let tagComponent = entity.components[GameTagComponent.self] {
                    if tagComponent.type == .powerup || tagComponent.type == .powerdown {
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
