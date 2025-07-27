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
    @Published var playerCurrentPosition: Int = 1
    
    @Published var playerProgress: Float = 0.0
    @Published var playerDistanceToFinish: Float = 0.0
    @Published var showPlayerFinished = false
    @Published var playerFinalPosition: Int = 1
    @Published var hasPlayedSlideSound = false
    @Published var botAITimer: Timer?
    @Published var powerEffectTimers: [String: Timer] = [:]
    
    private var finalPositions: [String: Int] = [:]
    private var positionSnapshot: [String: Int] = [:]
    private var allEntityPositions: [String: Int] = [:]
    private var totalEntityCount: Int = 4
    
    private var playerPenaltyEndTime: Date?
    private var botPenaltyEndTimes: [String: Date] = [:]
    
    private var startLineEntity: Entity?
    var finishEntity: Entity?
    private var totalRaceDistance: Float = 0.0
    private var finishLineZPosition: Float = 0.0
    private var playerHasCrossedFinish = false
    
    private var configuration = GameConfiguration()
    var racingEntities: [String: RacingEntity] = [:]
    private var gameStartTime: Date?
    
    private var countdownTimer: Timer?
    private var playerMovementTimer: Timer?  // Player's movement timer
    private var botMovementTimers: [String: Timer] = [:]  // Bot-specific timers
    private var boundaryCheckTimer: Timer?
    private var oneSec: Bool = false
    
    var onGameStart: (() -> Void)?
    var onGameEnd: (() -> Void)?
    var onCountdownFinish: (() -> Void)?
    var onReset: (() -> Void)?
    var onPowerEffectApplied: ((PowerEffectType) -> Void)?
    var onPowerEffectEnded: (() -> Void)?
    var onEffectVisualApplied: ((Entity, PowerEffectType) -> Void)?
    var onEffectVisualRemoved: ((Entity, PowerEffectType) -> Void)?
    var onEntityFinished: ((FinishInfo) -> Void)?
    var onAllEntitiesFinished: (([FinishInfo]) -> Void)?
    var gameConfig: GameConfiguration?
    var botAI_timer: Timer?
//    var boundaryCheckTimer: Timer?
        
    func checkSlideBoundary(for entity: Entity) {
        let name = getEntityName(entity)
        guard name == "player" else { fatalError("name is not player") }
        
        let config = gameConfig ?? configuration
        let x = entity.position.x
        _ = config.leftBoundary
        _ = config.rightBoundary

        if x <= -1.8 || x >= 1.8 {
            print("🎯 Menyentuh batas: \(x)")
            if !hasPlayedSlideSound {
                print("🔊 Mainkan suara slide")
                MusicController.shared.playSlideStoneSound()
                hasPlayedSlideSound = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.hasPlayedSlideSound = false
                }
            }
        } else {
            print("🎯 sudah aman")
        }
    }

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
        
        stopAllMovementClean()
        print("Game setup complete - \(racingEntities.count) entities ready")
    }
    
    func setStartLineEntity(_ entity: Entity) {
        self.startLineEntity = entity
        calculateTotalRaceDistance()
        print("🏁 Start line entity set: \(entity.name)")
    }
    
    func setFinishEntity(_ entity: Entity) {
        self.finishEntity = entity
        self.finishLineZPosition = entity.position.z
        calculateTotalRaceDistance()
        print("🏁 Finish line entity set: \(entity.name) at Z: \(finishLineZPosition)")
    }
    
    private func calculateTotalRaceDistance() {
        guard let startLine = startLineEntity,
              let finishLine = finishEntity else { return }
        
        totalRaceDistance = simd_distance(startLine.position, finishLine.position)
        print("📏 Total race distance calculated: \(totalRaceDistance)")
    }
    
    func startGame() {
        print("pos")
        guard gameState == .waiting else { return }
        
        gameState = .countdown
        showPlayButton = false
        canControlPlayer = false
        showLeaderboard = false
        finishedEntities.removeAll()
        gameStartTime = Date()
        
        clearAllPowerEffects()
        stopAllMovementClean()
        startCountdown()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await MusicController.shared.ensureAllSoundsLoaded()
                await MusicController.shared.playReadyGoAndThenBackground()
                print("🎵 Playing ready go and background music")
            }
        }
        
        print("🎯 Starting game with \(racingEntities.count) entities...")
    }
    
    func pauseGame() {
        guard gameState == .playing else { return }
        
        gameState = .paused
        canControlPlayer = false
        stopAllMovementClean()
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
        
        stopAllMovementClean()
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
        showPlayerFinished = false
        
        stopAllTimers()
        stopAllMovement()
        
        clearAllPowerEffects()
        currentPowerEffect = .none
        powerEffectTimeRemaining = 0.0
        
        finishedEntities.removeAll()
        gameStartTime = nil
        playerCurrentPosition = 1
        playerProgress = 0.0
        playerDistanceToFinish = 0.0
        playerHasCrossedFinish = false
        
        playerFinalPosition = 1
        allEntityPositions.removeAll()
        
        resetAllPositions()
        
        for (name, var racingEntity) in racingEntities {
            racingEntity.isFinished = false
            racingEntities[name] = racingEntity
        }

        finishedEntities.removeAll()
        
        onReset?()
        print("🔄 Game reset complete")
    }
    
    func restartGame() {
        print("🔄 Restarting game with countdown...")
        
        gameState = .waiting
        countdownNumber = 3
        isCountdownVisible = false
        showPlayButton = false 
        canControlPlayer = false
        showLeaderboard = false
        showPlayerFinished = false
        
        stopAllTimers()
        stopAllMovement()
        
        clearAllPowerEffects()
        currentPowerEffect = .none
        powerEffectTimeRemaining = 0.0
        
        finishedEntities.removeAll()
        gameStartTime = nil
        playerCurrentPosition = 1
        playerProgress = 0.0
        playerDistanceToFinish = 0.0
        playerHasCrossedFinish = false
        
        playerFinalPosition = 1
        allEntityPositions.removeAll()
        
        resetAllPositions()
        
        for (name, var racingEntity) in racingEntities {
            racingEntity.isFinished = false
            racingEntities[name] = racingEntity
        }

        finishedEntities.removeAll()
        
        onReset?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.startGame()
        }
        
        print("🔄 Game restart initiated - will start countdown automatically")
    }


    func playSound(named soundName: String, on entity: Entity) {
        do {
            let audioResource = try AudioFileResource.load(named: soundName)
            entity.playAudio(audioResource)
        } catch {
            print("❌ Gagal memuat suara \(soundName): \(error)")
        }
    }
    
    func applyPowerEffect(to entity: Entity, effectType: PowerEffectType, duration: Double) {
        guard gameState == .playing else { return }
        
        let entityName = getEntityName(entity)
        guard var racingEntity = racingEntities[entityName] else { return }
        
        if racingEntity.powerEffect == .shield {
            if effectType == .speedReduction || effectType == .splash {
                print("🛡️ Shield prevents effect: \(effectType)!")
                return
            }
        }
        
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
        
        onEffectVisualApplied?(racingEntity.entity, effectType)
        startPowerEffectTimer(for: entityName, duration: duration)
        print("💫 \(entityName) got \(effectType) for \(duration)s")
    }
    
    func handleObstacleCollision(entity: Entity, otherEntity: Entity) {
        guard gameState == .playing else { return }
        
        let entityName = getEntityName(entity)
        guard let racingEntity = racingEntities[entityName] else { return }
        
        if racingEntity.powerEffect == .shield {
            print("🛡️ \(entityName) protected by shield, no penalty.")
            return
        }

        print("⚠️ \(entityName) collided with obstacle!")

        if entityName == "player" {
            setPlayerPenaltyState(duration: 1.0)
        } else {
            setBotPenaltyState(botName: entityName, duration: 1.0)
        }
    }

    private func setPlayerPenaltyState(duration: Double) {
        playerPenaltyEndTime = Date().addingTimeInterval(duration)
        print("🚫 Player penalty for \(duration) seconds")
    }

    private func setBotPenaltyState(botName: String, duration: Double) {
        botPenaltyEndTimes[botName] = Date().addingTimeInterval(duration)
        print("🚫 Bot \(botName) penalty for \(duration) seconds")
    }

    private func isPlayerInPenalty() -> Bool {
        guard let endTime = playerPenaltyEndTime else { return false }
        if Date() > endTime {
            playerPenaltyEndTime = nil
            return false
        }
        return true
    }

    private func isBotInPenalty(_ botName: String) -> Bool {
        guard let endTime = botPenaltyEndTimes[botName] else { return false }
        if Date() > endTime {
            botPenaltyEndTimes[botName] = nil
            return false
        }
        return true
    }

    func checkFinish(for entity: Entity) {
        guard gameState == .playing,
              let finishEntity = finishEntity else { return }
        
        let entityName = getEntityName(entity)
        guard let racingEntity = racingEntities[entityName] else { return }
        
        if racingEntity.isFinished { return }
        
        let currentPosition = entity.position
        let finishPosition = finishEntity.position
        let distance = simd_distance(currentPosition, finishPosition)
        
        // Finish hanya jika distance sangat kecil (hampir menyentuh)
        let crossedFinishLine = distance <= 2.0
        
        if crossedFinishLine {
            print("🏁 \(entityName) crossed finish line at,\(distance)")
            
            if entityName == "player" && !playerHasCrossedFinish {
                playerHasCrossedFinish = true
                showPlayerFinishedMessage()
            }
            
            handleEntityFinished(entity)
        }
    }
    
    private func showPlayerFinishedMessage() {
        showPlayerFinished = true
        print("🎉 Player finished! Showing finish message...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showPlayerFinished = false
            self.showLeaderboardAfterPlayerFinish()
        }
    }
    
    private func showLeaderboardAfterPlayerFinish() {
        addRemainingEntitiesToFinished()
        
        showLeaderboard = true
        onAllEntitiesFinished?(finishedEntities)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.endGame()
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
            default:
                break
            }
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
        
        print("✅ Stable physics setup for: \(entity.name)")
    }
    
    func startCountdown() {
        print ("Start Count Down")
        countdownNumber = 3
        isCountdownVisible = true
 
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print ("timer count")
            self.updateCountdown()
        }

        print("🔁 Countdown started from 3")
    }
    
    private func updateCountdown() {
        if countdownNumber > 0 {
            print("⏱️ Countdown now: \(countdownNumber)")
            countdownNumber -= 1
        } else {
            stopCountdownTimer()
            isCountdownVisible = false
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
        playerMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            guard self.gameState == .playing else { return }
                
            self.updateAllEntitiesMovement()
            self.updateBoundariesAndPositions()
            self.updateFinishChecking()
        }
            
        startBotAI()
    }
    
    private func updateAllEntitiesMovement() {
        if let playerEntity = racingEntities["player"] {
            if isPlayerInPenalty() {
                applyBackwardMovement(to: playerEntity.entity, racingEntity: playerEntity)
            } else {
                applyForwardMovement(to: playerEntity.entity, racingEntity: playerEntity)
            }
            checkSlideBoundary(for: playerEntity.entity)
        }
        
        // Update bots dengan penalty check
        for (botName, racingEntity) in racingEntities where racingEntity.type == .bot {
            if isBotInPenalty(botName) {
                applyBackwardMovement(to: racingEntity.entity, racingEntity: racingEntity)
            } else {
                applyForwardMovement(to: racingEntity.entity, racingEntity: racingEntity)
            }
        }
    }

    private func updateBoundariesAndPositions() {
        checkPlayerBoundaries()
        updatePlayerPosition()
    }

    private func updateFinishChecking() {
        for (_, racingEntity) in racingEntities {
            checkFinish(for: racingEntity.entity)
        }
    }
    
    private func stopAllMovement() {
        stopAllTimers()
        freezeAllEntities()
    }
    
    private func stopAllMovementClean() {
        stopAllTimers()
        
        for (_, racingEntity) in racingEntities {
            var motion = racingEntity.entity.components[PhysicsMotionComponent.self] ?? PhysicsMotionComponent()
            motion.linearVelocity = SIMD3<Float>(0, 0, 0)
            motion.angularVelocity = SIMD3<Float>(0, 0, 0)
            racingEntity.entity.components.set(motion)
        }
        
    }
    private func startForwardMovement() {
        // Start the player's forward movement
        startPlayerMovement()
        
        // Start the bots' forward movement
        startBotsMovement()
    }

    //FCS: Start the player's forward movement
    private func startPlayerMovement() {
        guard self.gameState == .playing else { return }

        playerMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            guard self.gameState == .playing else { return }

            if let playerEntity = self.racingEntities["player"] {
                self.applyForwardMovement(to: playerEntity.entity, racingEntity: playerEntity)

                // Tambahan untuk mengecek posisi dan mainkan sound
                self.checkSlideBoundary(for: playerEntity.entity)
            }
        }
    }
    
    

    //FCS: Start the bots' forward movement independently
    private func startBotsMovement() {
        for (botName, racingEntity) in self.racingEntities where racingEntity.type == .bot {
            // Start a movement timer for each bot
            botMovementTimers[botName] = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                guard self.gameState == .playing else { return }
                
                if let botEntity = self.racingEntities[botName] {
                    self.applyForwardMovement(to: botEntity.entity, racingEntity: botEntity)
                }
            }
        }
    }
    
    //FCS:
    private func stopPlayerMovement() {
        playerMovementTimer?.invalidate()  // Stop the player's movement timer
        playerMovementTimer = nil  // Reset the timer
    }
    
    //FCS:
    private func stopBotMovement(botName: String) {
        botMovementTimers[botName]?.invalidate()  // Stop the bot's movement timer
        botMovementTimers[botName] = nil  // Reset the timer
    }

    
    //FCS: ini dipanggil setiap waktu
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
        default:
            break
        }
        
        let targetVelocityZ = -entitySpeed
        let currentVelocityZ = motion.linearVelocity.z
        
        // ✅ SMOOTH TRANSITION INSTEAD OF INSTANT CHANGE
        let lerpFactor: Float = 0.15  // Adjust untuk smoothness
        let newVelocityZ = currentVelocityZ + (targetVelocityZ - currentVelocityZ) * lerpFactor
        
        motion.linearVelocity.z = newVelocityZ
        entity.components.set(motion)
    }
    
    private func applyBackwardMovement(to entity: Entity, racingEntity: RacingEntity) {
        guard var motion = entity.components[PhysicsMotionComponent.self] else { return }

        let targetVelocityZ: Float = 6.0  // Backward speed
        let currentVelocityZ = motion.linearVelocity.z
        
        // ✅ SMOOTH BACKWARD TRANSITION
        let lerpFactor: Float = 0.2
        let newVelocityZ = currentVelocityZ + (targetVelocityZ - currentVelocityZ) * lerpFactor
        
        motion.linearVelocity.z = newVelocityZ
        motion.linearVelocity.x *= 0.8  // Gradual horizontal reduction
        motion.linearVelocity.y = 0.0
        
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
            self.updatePlayerPosition()
        }
    }
    
    private func checkPlayerBoundaries() {
        guard gameState == .playing,
              let player = getPlayerEntity(),
              var motion = player.components[PhysicsMotionComponent.self] else { return }
        
        let currentX = player.position.x
        let buffer: Float = 0.2  // Lebih besar untuk smooth transition
        
        if currentX < configuration.leftBoundary + buffer {
            // Hitung seberapa jauh dari boundary
            let distance = (configuration.leftBoundary + buffer) - currentX
            let pushForce = distance * 3.0  // Semakin jauh, semakin kuat push
            
            // Hanya push jika sedang bergerak ke kiri atau diam
            if motion.linearVelocity.x <= 0 {
                motion.linearVelocity.x = max(motion.linearVelocity.x, pushForce)
                player.components.set(motion)
                print("🔄 Boundary push RIGHT: \(pushForce)")
            }
            
        } else if currentX > configuration.rightBoundary - buffer {
            // Hitung seberapa jauh dari boundary
            let distance = currentX - (configuration.rightBoundary - buffer)
            let pushForce = -(distance * 3.0)  // Negative untuk push ke kiri
            
            // Hanya push jika sedang bergerak ke kanan atau diam
            if motion.linearVelocity.x >= 0 {
                motion.linearVelocity.x = min(motion.linearVelocity.x, pushForce)
                player.components.set(motion)
                print("🔄 Boundary push LEFT: \(pushForce)")
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
        
        if var racingEntity = racingEntities[entityName] {
            racingEntity.isFinished = true
            racingEntities[entityName] = racingEntity
        }
        
        let finishPosition = finishedEntities.count + 1
        
        if entityName == "player" {
            print("🎯 Player finished at position: \(playerFinalPosition)")
        }
        
        
        let finishInfo = FinishInfo(
            entityName: entityName,
            finishTime: Date(),
            position: finishPosition
        )
        
        finishedEntities.append(finishInfo)
        onEntityFinished?(finishInfo)
        
        print("🏁 \(entityName) finished in position \(finishPosition)")
        
    }
    
    
    private func addRemainingEntitiesToFinished() {
        guard let finishEntity = finishEntity else { return }
        
        var remainingEntities: [(name: String, distance: Float)] = []
        
        for (name, racingEntity) in racingEntities {
            if !finishedEntities.contains(where: { $0.entityName == name }) {
                let distance = simd_distance(racingEntity.entity.position, finishEntity.position)
                remainingEntities.append((name: name, distance: distance))
            }
        }
        
        // Sort by distance (closest to finish first)
        remainingEntities.sort { $0.distance < $1.distance }
        
        // Add remaining entities to finished list
        for (name, _) in remainingEntities {
            let finishInfo = FinishInfo(
                entityName: name,
                finishTime: Date(),
                position: finishedEntities.count + 1
            )
            finishedEntities.append(finishInfo)
            
            // Mark as finished in racingEntities too
            if var racingEntity = racingEntities[name] {
                racingEntity.isFinished = true
                racingEntities[name] = racingEntity
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
            onEffectVisualRemoved?(racingEntity.entity, racingEntity.powerEffect)
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
        
    func getEntityName(_ entity: Entity) -> String {
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
        playerMovementTimer?.invalidate()
        playerMovementTimer = nil
        
        for (_, botTimer) in botMovementTimers {
            botTimer.invalidate()
        }
        botMovementTimers.removeAll()
        botAITimer?.invalidate()
        botAITimer = nil

        
        for (entityName, _) in powerEffectTimers {
            powerEffectTimers[entityName]?.invalidate()
        }
        powerEffectTimers.removeAll()
    }
    
    func cleanup() {
        stopAllTimers()
        stopAllMovementClean()
        clearAllPowerEffects()
        racingEntities.removeAll()
        finishedEntities.removeAll()
        print("🧹 GameController cleanup completed")
    }
    
    private func updatePlayerPosition() {
        guard gameState == .playing,
              let player = getPlayerEntity(),
              let finishEntity = finishEntity else {
            playerCurrentPosition = 1
            playerProgress = 0.0
            playerDistanceToFinish = 0.0
            return
        }
        
        updatePlayerProgress()
        
        var allEntityDistances: [(name: String, distance: Float, isPlayer: Bool, isFinished: Bool)] = []
        
        for (name, racingEntity) in racingEntities {
            let distance = simd_distance(racingEntity.entity.position, finishEntity.position)
            let isPlayer = (name == "player")
            let isFinished = racingEntity.isFinished
            
            allEntityDistances.append((
                name: name,
                distance: distance,
                isPlayer: isPlayer,
                isFinished: isFinished
            ))
        }
        
        allEntityDistances.sort { entity1, entity2 in
            if entity1.isFinished && !entity2.isFinished {
                return true
            } else if !entity1.isFinished && entity2.isFinished {
                return false
            } else {
                return entity1.distance < entity2.distance
            }
        }
        
        for (index, entityInfo) in allEntityDistances.enumerated() {
            let newPosition = min(index + 1, totalEntityCount)
            allEntityPositions[entityInfo.name] = newPosition
            
            if entityInfo.isPlayer {
                playerDistanceToFinish = entityInfo.distance
                
                if !entityInfo.isFinished {
                    playerCurrentPosition = newPosition
                    playerFinalPosition = newPosition
                }
            }
        }
    }
    
    func getCurrentLeaderboard() -> [(name: String, distance: Float, position: Int)] {
        guard let finishEntity = finishEntity else { return [] }
        
        var entityDistances: [(name: String, distance: Float)] = []
        
        for (name, racingEntity) in racingEntities {
            if finishedEntities.contains(where: { $0.entityName == name }) {
                continue
            }
            
            let distance = simd_distance(racingEntity.entity.position, finishEntity.position)
            entityDistances.append((name: name, distance: distance))
        }
        
        entityDistances.sort { $0.distance < $1.distance }
        
        var leaderboard: [(name: String, distance: Float, position: Int)] = []
        for (index, entityInfo) in entityDistances.enumerated() {
            leaderboard.append((name: entityInfo.name, distance: entityInfo.distance, position: index + 1))
        }
        
        return leaderboard
    }
    
    private func updatePlayerProgress() {
        guard let player = getPlayerEntity(),
              let startLine = startLineEntity,
              let finishLine = finishEntity,
              totalRaceDistance > 0 else {
            playerProgress = 0.0
            return
        }
        
        let playerPosition = player.position
        let startPosition = startLine.position
        let finishPosition = finishLine.position
        
        let playerZ = playerPosition.z
        let startZ = startPosition.z
        let finishZ = finishPosition.z
        
        let distanceTraveled = startZ - playerZ
        let totalDistance = startZ - finishZ
        
        if totalDistance > 0 {
            playerProgress = max(0.0, min(1.0, distanceTraveled / totalDistance))
        } else {
            playerProgress = 0.0
        }
    }
    
    func resetPlayerPosition() {
        playerCurrentPosition = 1
        playerProgress = 0.0
        playerDistanceToFinish = 0.0
        showPlayerFinished = false
        playerHasCrossedFinish = false
    }
    func getAllEntityPositions() -> [String: Int] {
        return allEntityPositions
    }
    
    func getEntityPosition(_ entityName: String) -> Int {
        return allEntityPositions[entityName] ?? totalEntityCount
    }

}
