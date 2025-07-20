//
//  GameController.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI
import RealityKit
import Combine

class GameController: ObservableObject {
    
    @Published var gameState: GameState = .waiting
    @Published var countdownNumber: Int = 3
    @Published var isCountdownVisible = false
    @Published var showPlayButton = true
    @Published var canControlPlayer = false
    @Published var currentPowerEffect: PowerEffectType = .none
    @Published var powerEffectTimeRemaining: Double = 0.0
    @Published var finishedEntities: [FinishInfo] = []
    @Published var showLeaderboard = false
    
    private var configuration = GameConfiguration()
    private var racingEntities: [String: RacingEntity] = [:]
    private var finishEntity: Entity?
    private var gameStartTime: Date?
    
    private var countdownTimer: Timer?
    private var movementTimer: Timer?
    private var botAITimer: Timer?
    private var boundaryCheckTimer: Timer?
    private var powerEffectTimers: [String: Timer] = [:]
    
    var onGameStart: (() -> Void)?
    var onGameEnd: (() -> Void)?
    var onCountdownFinish: (() -> Void)?
    var onReset: (() -> Void)?
    var onPowerEffectApplied: ((PowerEffectType) -> Void)?
    var onPowerEffectEnded: (() -> Void)?
    var onEntityFinished: ((FinishInfo) -> Void)?
    var onAllEntitiesFinished: (([FinishInfo]) -> Void)?
        
    func configure(with config: GameConfiguration) {
        self.configuration = config
    }
    
    func setEntities(player: Entity?, bots: [Entity]) {
        racingEntities.removeAll()
        
        if let player = player {
            let playerEntity = RacingEntity(
                entity: player,
                name: "player",
                type: .player,
                originalSpeed: configuration.forwardSpeed,
                
                startingPosition: player.position,
                startingOrientation: player.orientation
            )
            racingEntities["player"] = playerEntity
            setupEntityPhysics(player)
            print("🎯 Player setup: \(player.name)")
        }
        
        for (index, bot) in bots.enumerated() {
            let botName = "bot_\(index)"
            let botEntity = RacingEntity(
                entity: bot,
                name: botName,
                type: .bot,
                originalSpeed: configuration.forwardSpeed,
                
                startingPosition: bot.position,
                startingOrientation: bot.orientation
            )
            racingEntities[botName] = botEntity
            setupEntityPhysics(bot)
            print("🤖 Bot \(index + 1) setup: \(bot.name)")
        }
        
        stopAllMovement()
        print("✅ Game setup complete - \(racingEntities.count) entities ready")
    }
    
    func setFinishEntity(_ entity: Entity) {
        self.finishEntity = entity
        print("🏁 Finish entity set: \(entity.name)")
    }
    
    // MARK: - Game Flow Control
    
    func startGame() {
        guard gameState == .waiting else { return }
        
        gameState = .countdown
        showPlayButton = false
        canControlPlayer = false
        showLeaderboard = false
        finishedEntities.removeAll()
        gameStartTime = Date()
        
        clearAllPowerEffects()
        stopAllMovement()
        startCountdown()
        
        print("🎯 Starting game with \(racingEntities.count) entities...")
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        
        gameState = .paused
        canControlPlayer = false
        stopAllMovement()
        pauseAllPowerEffectTimers()
        
        print("⏸️ Game paused")
    }
    
    func resumeGame() {
        guard gameState == .paused else { return }
        
        gameState = .playing
        canControlPlayer = true
        startAllMovement()
        resumeAllPowerEffectTimers()
        
        print("▶️ Game resumed")
    }
    
    func endGame() {
        gameState = .finished
        canControlPlayer = false
        showPlayButton = true
        
        stopAllMovement()
        clearAllPowerEffects()
        showLeaderboard = true
        
        onGameEnd?()
        print("🏁 Game ended")
    }
    
    func resetGame() {
        gameState = .waiting
        countdownNumber = 3
        isCountdownVisible = false
        showPlayButton = true
        canControlPlayer = false
        showLeaderboard = false
        
        stopAllTimers()
        stopAllMovement()
        resetAllPositions()
        clearAllPowerEffects()
        finishedEntities.removeAll()
        
        onReset?()
        print("🔄 Game reset complete")
    }
        
    func applyPowerEffect(to entity: Entity, effectType: PowerEffectType, duration: Double) {
        guard gameState == .playing else { return }
        
        let entityName = getEntityName(entity)
        guard var racingEntity = racingEntities[entityName] else { return }
        
        clearPowerEffectForEntity(entityName)
        
        racingEntity.powerEffect = effectType
        racingEntity.powerEffectTimeRemaining = duration
        racingEntities[entityName] = racingEntity
        
        // Update UI if it's the player
        if entityName == "player" {
            currentPowerEffect = effectType
            powerEffectTimeRemaining = duration
            onPowerEffectApplied?(effectType)
        }
        
        startPowerEffectTimer(for: entityName, duration: duration)
        print("💫 \(entityName) got \(effectType) for \(duration)s")
    }
        
    func checkFinish(for entity: Entity) {
        guard gameState == .playing,
              let finishEntity = finishEntity else { return }
        
        let distance = simd_distance(entity.position, finishEntity.position)
        
        if distance < 2.0 {
            handleEntityFinished(entity)
        }
    }
        
    func applyPlayerHorizontalMovement(_ horizontalVelocity: Float) {
        guard gameState == .playing,
              let player = getPlayerEntity(),
              var motion = player.components[PhysicsMotionComponent.self] else { return }
        
        motion.linearVelocity.x = horizontalVelocity
        
        // Apply current speed with power effects
        if let playerEntity = racingEntities["player"] {
            var speed = playerEntity.originalSpeed
            
            switch playerEntity.powerEffect {
            case .speedBoost:
                speed *= 2.0
            case .speedReduction:
                speed *= 0.3
            case .none:
                break
            }
            
            motion.linearVelocity.z = -speed
        }
        
        player.components.set(motion)
    }
        
    private func setupEntityPhysics(_ entity: Entity) {
        if entity.components[PhysicsBodyComponent.self] == nil {
            entity.components.set(PhysicsBodyComponent(
                massProperties: .default,
                material: .default,
                mode: .dynamic
            ))
        }
        
        if entity.components[PhysicsMotionComponent.self] == nil {
            entity.components.set(PhysicsMotionComponent())
        }
        
        var motion = entity.components[PhysicsMotionComponent.self]!
        motion.linearVelocity = SIMD3<Float>(0, 0, 0)
        motion.angularVelocity = SIMD3<Float>(0, 0, 0)
        entity.components.set(motion)
    }
    
    private func startCountdown() {
        countdownNumber = 3
        isCountdownVisible = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: configuration.countdownDuration, repeats: true) { _ in
            self.updateCountdown()
        }
    }
    
    private func updateCountdown() {
        if countdownNumber > 1 {
            countdownNumber -= 1
        } else {
            finishCountdown()
        }
    }
    
    private func finishCountdown() {
        stopCountdownTimer()
        isCountdownVisible = false
        
        gameState = .playing
        canControlPlayer = true
        gameStartTime = Date()
        
        startAllMovement()
        onCountdownFinish?()
        onGameStart?()
        
        print("🚀 Game started!")
    }
    
    private func startAllMovement() {
        startForwardMovement()
        startBotAI()
        startBoundaryCheck()
    }
    
    private func stopAllMovement() {
        stopAllTimers()
        freezeAllEntities()
    }
    
    private func startForwardMovement() {
        movementTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            guard self.gameState == .playing else { return }
            
            for (_, racingEntity) in self.racingEntities {
                self.applyForwardMovement(to: racingEntity.entity, racingEntity: racingEntity)
            }
        }
    }
    
    private func applyForwardMovement(to entity: Entity, racingEntity: RacingEntity) {
        guard var motion = entity.components[PhysicsMotionComponent.self] else { return }
        
        var entitySpeed = racingEntity.originalSpeed
        
        switch racingEntity.powerEffect {
        case .speedBoost:
            entitySpeed *= 2.0
        case .speedReduction:
            entitySpeed *= 0.3
        case .none:
            break
        }
        
        motion.linearVelocity.z = -entitySpeed
        motion.linearVelocity.x *= 0.98
        motion.linearVelocity.y *= 0.95
        
        entity.components.set(motion)
    }
    
    private func startBotAI() {
        botAITimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            guard self.gameState == .playing else { return }
            
            for (name, racingEntity) in self.racingEntities {
                if racingEntity.type == .bot {
                    self.updateBotAI(racingEntity.entity, name: name)
                }
            }
        }
    }
    
    private func updateBotAI(_ bot: Entity, name: String) {
        guard var motion = bot.components[PhysicsMotionComponent.self] else { return }
        
        let currentX = bot.position.x
        let randomDirection = Float.random(in: -1.0...1.0)
        var targetHorizontalSpeed = randomDirection * 0.8
        
        if currentX <= configuration.leftBoundary && targetHorizontalSpeed < 0 {
            targetHorizontalSpeed = abs(targetHorizontalSpeed)
        } else if currentX >= configuration.rightBoundary && targetHorizontalSpeed > 0 {
            targetHorizontalSpeed = -abs(targetHorizontalSpeed)
        }
        
        let speedDiff = targetHorizontalSpeed - motion.linearVelocity.x
        motion.linearVelocity.x += speedDiff * 0.1
        
        bot.components.set(motion)
    }
    
    private func startBoundaryCheck() {
        boundaryCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.checkPlayerBoundaries()
            self.checkAllEntitiesFinish()
        }
    }
    
    private func checkPlayerBoundaries() {
        guard gameState == .playing,
              let player = getPlayerEntity() else { return }
        
        let currentX = player.position.x
        
        if currentX < configuration.leftBoundary {
            player.position.x = configuration.leftBoundary
            if var motion = player.components[PhysicsMotionComponent.self] {
                motion.linearVelocity.x = max(0, motion.linearVelocity.x)
                player.components.set(motion)
            }
        } else if currentX > configuration.rightBoundary {
            player.position.x = configuration.rightBoundary
            if var motion = player.components[PhysicsMotionComponent.self] {
                motion.linearVelocity.x = min(0, motion.linearVelocity.x)
                player.components.set(motion)
            }
        }
    }
    
    private func checkAllEntitiesFinish() {
        guard gameState == .playing else { return }
        
        for (_, racingEntity) in racingEntities {
            checkFinish(for: racingEntity.entity)
        }
    }
    
    private func handleEntityFinished(_ entity: Entity) {
        let entityName = getEntityName(entity)
        
        if finishedEntities.contains(where: { $0.entityName == entityName }) {
            return
        }
        
        let finishInfo = FinishInfo(
            entityName: entityName,
            finishTime: Date(),
            position: finishedEntities.count + 1
        )
        
        finishedEntities.append(finishInfo)
        onEntityFinished?(finishInfo)
        
        if finishedEntities.count >= racingEntities.count {
            showLeaderboard = true
            onAllEntitiesFinished?(finishedEntities)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.endGame()
            }
        }
    }
        
    private func startPowerEffectTimer(for entityName: String, duration: Double) {
        powerEffectTimers[entityName]?.invalidate()
        powerEffectTimers[entityName] = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updatePowerEffectTimer(for: entityName)
        }
    }
    
    private func updatePowerEffectTimer(for entityName: String) {
        guard var racingEntity = racingEntities[entityName] else { return }
        
        racingEntity.powerEffectTimeRemaining -= 0.1
        racingEntities[entityName] = racingEntity
        
        if entityName == "player" {
            powerEffectTimeRemaining = racingEntity.powerEffectTimeRemaining
        }
        
        if racingEntity.powerEffectTimeRemaining <= 0 {
            clearPowerEffectForEntity(entityName)
        }
    }
    
    private func clearPowerEffectForEntity(_ entityName: String) {
        powerEffectTimers[entityName]?.invalidate()
        powerEffectTimers[entityName] = nil
        
        guard var racingEntity = racingEntities[entityName] else { return }
        
        if racingEntity.powerEffect != .none {
            racingEntity.powerEffect = .none
            racingEntity.powerEffectTimeRemaining = 0.0
            racingEntities[entityName] = racingEntity
            
            if entityName == "player" {
                currentPowerEffect = .none
                powerEffectTimeRemaining = 0.0
                onPowerEffectEnded?()
            }
        }
    }
    
    private func pauseAllPowerEffectTimers() {
        for (entityName, _) in powerEffectTimers {
            powerEffectTimers[entityName]?.invalidate()
        }
    }
    
    private func resumeAllPowerEffectTimers() {
        for (entityName, racingEntity) in racingEntities {
            if racingEntity.powerEffect != .none && racingEntity.powerEffectTimeRemaining > 0 {
                startPowerEffectTimer(for: entityName, duration: racingEntity.powerEffectTimeRemaining)
            }
        }
    }
    
    private func clearAllPowerEffects() {
        for entityName in racingEntities.keys {
            clearPowerEffectForEntity(entityName)
        }
        currentPowerEffect = .none
        powerEffectTimeRemaining = 0.0
    }
        
    private func getEntityName(_ entity: Entity) -> String {
        for (name, racingEntity) in racingEntities {
            if racingEntity.entity === entity {
                return name
            }
        }
        return entity.name
    }
    
    private func getPlayerEntity() -> Entity? {
        return racingEntities["player"]?.entity
    }
    
    private func freezeAllEntities() {
        for (_, racingEntity) in racingEntities {
            var motion = racingEntity.entity.components[PhysicsMotionComponent.self] ?? PhysicsMotionComponent()
            motion.linearVelocity = SIMD3<Float>(0, 0, 0)
            motion.angularVelocity = SIMD3<Float>(0, 0, 0)
            racingEntity.entity.components.set(motion)
        }
    }
    
    private func resetAllPositions() {
        print("🔄 Resetting all entities to starting positions...")
            
        for (entityName, racingEntity) in racingEntities {
            resetEntityToStartingPosition(entityName: entityName, racingEntity: racingEntity)
        }
            
        print("✅ All entities reset to starting positions successfully")
    }
    
    private func resetEntityToStartingPosition(entityName: String, racingEntity: RacingEntity) {
        let entity = racingEntity.entity
        
        entity.position = racingEntity.startingPosition
        entity.orientation = racingEntity.startingOrientation
        
        if var motion = entity.components[PhysicsMotionComponent.self] {
            motion.linearVelocity = SIMD3<Float>(0, 0, 0)
            motion.angularVelocity = SIMD3<Float>(0, 0, 0)
            entity.components.set(motion)
        }
        
        var updatedEntity = racingEntity
        updatedEntity.isFinished = false
        updatedEntity.powerEffect = .none
        updatedEntity.powerEffectTimeRemaining = 0.0
        racingEntities[entityName] = updatedEntity
    }
    
    func forceResetToStartingPositions() {
        print("🔧 Force resetting all entities to starting positions...")
        resetAllPositions()
    }
        
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func stopAllTimers() {
        stopCountdownTimer()
        movementTimer?.invalidate()
        movementTimer = nil
        botAITimer?.invalidate()
        botAITimer = nil
        boundaryCheckTimer?.invalidate()
        boundaryCheckTimer = nil
        
        for (entityName, _) in powerEffectTimers {
            powerEffectTimers[entityName]?.invalidate()
        }
        powerEffectTimers.removeAll()
    }
        
    func cleanup() {
        stopAllTimers()
        stopAllMovement()
        clearAllPowerEffects()
        racingEntities.removeAll()
        finishedEntities.removeAll()
        print("🧹 GameController cleanup completed")
    }
}
