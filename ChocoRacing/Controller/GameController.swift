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
    
    private var finalPositions: [String: Int] = [:]
    private var positionSnapshot: [String: Int] = [:]
    private var allEntityPositions: [String: Int] = [:]
    private var totalEntityCount: Int = 4
    
    private var startLineEntity: Entity?
    var finishEntity: Entity?
    private var totalRaceDistance: Float = 0.0
    private var finishLineZPosition: Float = 0.0
    private var playerHasCrossedFinish = false
    
    private var configuration = GameConfiguration()
    var racingEntities: [String: RacingEntity] = [:]
    var obstacleEntities: [Entity] = []
    private var gameStartTime: Date?
    
    private var countdownTimer: Timer?
    private var playerMovementTimer: Timer?  // Player's movement timer
    private var botMovementTimers: [String: Timer] = [:]  // Bot-specific timers

    private var botAITimer: Timer?
    private var boundaryCheckTimer: Timer?
    private var powerEffectTimers: [String: Timer] = [:]
    
    private var oneSec: Bool = false
    private var hasPlayedSlideSound = false
    
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
        
    func checkSlideBoundary(for entity: Entity) {
        let name = getEntityName(entity)
        guard name == "player" else { fatalError("name is not player") }
        
//        guard let config = gameConfig else { fatalError("config is nil")  }
        let config = gameConfig ?? configuration
        let x = entity.position.x
        let left = config.leftBoundary
        let right = config.rightBoundary

        if x <= -1.5 || x >= 1.8 {
            print("🎯 Menyentuh batas: \(x)")
            if !hasPlayedSlideSound {
                print("🔊 Mainkan suara slide")
                MusicController.shared.playSlideStoneSound()
                hasPlayedSlideSound = true

                // Reset flag setelah 1 detik
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.hasPlayedSlideSound = false
                }
            }
        } else {
            // kalau bukan x <= -1.5 || x >= 1.8
//            print("🎯 sudah aman")
        }
    }

    func configure(with config: GameConfiguration) {
        self.configuration = config
    }
    
    func setObstacleEntities(_ obstacles: [Entity]) {
        self.obstacleEntities = obstacles
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
        print("ini ke stop 1")
        stopAllMovement()
        print("✅ Game setup complete - \(racingEntities.count) entities ready")
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
        stopAllMovement()
        startCountdown()
        print("ini setelah start countdown")
        Task {
            await MusicController.shared.playReadyGoAndThenBackground()
        }
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
        //loop untuk setiap racingentities
        for (_, racingEntity) in racingEntities {
           lockTranslation(for: racingEntity.entity, lockX: false, lockY: false, lockZ: false)
        }
           
        print("🏁 Game ended")
    }
    
    func resetGame() {
        print("reset game")
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
        MusicController.shared.playBeforePlayMusic()
        startCountdown()
        
        onReset?()
        print("🔄 Game reset complete")
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
        guard var racingEntity = racingEntities[entityName] else { return }
        
        // Jika punya shield, tidak kena penalti
        if racingEntity.powerEffect == .shield {
            print("🛡️ \(entityName) protected by shield, no penalty.")
            return
        }

        print("⚠️ \(entityName) collided with obstacle!")

        // Hentikan gerakan sementara
        if entityName == "player"{
            stopPlayerMovement()
            playerMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                guard self.gameState == .playing else { return }
                
                if let playerEntity = self.racingEntities["player"] {
                    self.applyBackwardMovement(to: playerEntity.entity, racingEntity: playerEntity)
                }
            }
            
        } else {
            print("Stop bot \(entityName)")
            stopBotMovement(botName: entityName)
            self.botMovementTimers[entityName] = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                guard self.gameState == .playing else { return }
                if let botEntity = self.racingEntities[entityName] {
                    self.applyBackwardMovement(to: botEntity.entity, racingEntity: botEntity)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.gameState == .playing {
                if entityName == "player" {
                    self.stopPlayerMovement()
                    self.startPlayerMovement()
                } else {
                    self.stopBotMovement(botName: entityName)
                    self.botMovementTimers[entityName] = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                        guard self.gameState == .playing else { return }
                        if let botEntity = self.racingEntities[entityName] {
                            self.applyForwardMovement(to: botEntity.entity, racingEntity: botEntity)
                        }
                    }
                }
                print("✅ \(entityName) resumed after penalty")
            }
        }
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
            
//            motion.linearVelocity.z = -speed
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
    
    func startCountdown() {
        print ("Start Count Down")
        countdownNumber = 3
        isCountdownVisible = true
 
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            print ("timer count 1")
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
       //loop untuk setiap racingentities
       for (_, racingEntity) in racingEntities {
          lockTranslation(for: racingEntity.entity, lockX: false, lockY: true, lockZ: false)
       }
          
        print("🚀 Game started!")
    }
    
    private func startAllMovement() {
        startForwardMovement()
        startBotAI()
        startBoundaryCheck()
    }
    
    private func stopAllMovement() {
        print("stop al movement")
        stopAllTimers()
        freezeAllEntities()
    }
    
    //FCS
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
//        print("move forward")
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
        
        motion.linearVelocity.z = -entitySpeed
        motion.linearVelocity.x *= 0.98
        motion.linearVelocity.y *= 0.95
        
        entity.components.set(motion)
    }
    
    //FCS
    private func applyBackwardMovement(to entity: Entity, racingEntity: RacingEntity) {
        guard var motion = entity.components[PhysicsMotionComponent.self] else { return }
        // Dorong ke belakang (z positif)
        motion.linearVelocity.z = 8.0  // dorong ke belakang dengan kecepatan 8

        // Kurangi kontrol horizontal untuk mencegah pergerakan lateral
        motion.linearVelocity.x *= 0.3  // Kurangi kontrol horizontal
        motion.linearVelocity.y = 0.0  // Netralisir gerakan vertikal (menghindari lonjakan)

        entity.components.set(motion)  // Terapkan perubahan pada entitas
    }
    
    private func startBotAI() {
        botAITimer = Timer.scheduledTimer(withTimeInterval:   0.016, repeats: true) { _ in
            guard self.gameState == .playing else { return }
            
            for (name, racingEntity) in self.racingEntities {
                if racingEntity.type == .bot {
//                    print("INI KEPANGGILLLL BOT AIIIIIIIIIIIIIIIIFF")
                    self.updateBotAI(racingEntity.entity, name: name)
                }
            }
        }
    }
    
//    private func updateBotAI(_ bot: Entity, name: String) {
//        guard var motion = bot.components[PhysicsMotionComponent.self] else { return }
//
//        let currentX = bot.position.x
//
//        // Tentukan arah acak: -1 untuk kiri, 1 untuk kanan
//        let direction: Float = Bool.random() ? -1.0 : 1.0
//        var horizontalSpeed: Float = direction * Float.random(in: 0.3...1.2)
//
//        // Koreksi jika bot menyentuh batas lintasan
//        if currentX <= configuration.leftBoundary && direction < 0 {
//            horizontalSpeed = abs(horizontalSpeed) // Paksa ke kanan
//        } else if currentX >= configuration.rightBoundary && direction > 0 {
//            horizontalSpeed = -abs(horizontalSpeed) // Paksa ke kiri
//        }
//
//        // Set langsung velocity horizontal
//        motion.linearVelocity.x = horizontalSpeed
//        bot.components.set(motion)
//
//        // Log nama bot dan velocity-nya
//        let arah = horizontalSpeed > 0 ? "kanan ➡️" : "kiri ⬅️"
//        print("🤖 \(name) bergerak ke \(arah) dengan velocityX = \(String(format: "%.2f", horizontalSpeed))")
//    }
    
    //BCS:Start
    private func updateBotAI(_ bot: Entity, name: String) {
        guard var motion = bot.components[PhysicsMotionComponent.self] else { return }

        if let targetX = findSafeXTarget(for: bot, obstacles: obstacleEntities) {
            let currentX = bot.position.x
            let diff = targetX - currentX

            let arah = diff > 0 ? "kanan ➡️" : "kiri ⬅️"
            print("🤖 \(name) memilih jalur aman di x = \(String(format: "%.2f", targetX)) → belok ke \(arah)")

            motion.linearVelocity.x = (diff > 0 ? 1 : -1) * Float.random(in: 0.8...1.2)
        } else {
            print("⚠️ \(name) tidak menemukan jalur aman, tetap lurus")
            motion.linearVelocity.x = 0
        }

        bot.components.set(motion)
    }

    
    private func findSafeXTarget(for bot: Entity, obstacles: [Entity], zRange: Float = 15.0, sideTolerance: Float = 0.5) -> Float? {
        let botPos = bot.position
        let left = configuration.leftBoundary
        let right = configuration.rightBoundary

        var leftBlocked = false
        var rightBlocked = false

        for obs in obstacles {

            let dz = botPos.z - obs.position.z
            let x = obs.position.x

            if dz > 0 && dz <= zRange {
                if abs(x - left) < sideTolerance {
                    leftBlocked = true
                }
                if abs(x - right) < sideTolerance {
                    rightBlocked = true
                }
            }
        }

        // Logika yang kamu minta
        if !rightBlocked {
            print("🟢 Kanan aman → pilih ke kanan")
            return right - 0.2 // ke arah kanan
        } else if !leftBlocked {
            print("🟢 Kiri aman → pilih ke kiri")
            return left + 0.2 // ke arah kiri
        } else {
            print("⚠️ Kanan & kiri terblokir → fallback ke tengah")

            // Fallback: cari posisi aman yang tidak terlalu pinggir
            let midLeft = left + 0.5
            let midRight = right - 0.5
            let candidates: [Float] = [midLeft, midRight]

            for x in candidates {
                let isBlocked = obstacles.contains { obs in
                    guard let tag = obs.components[GameTagComponent.self]?.type, tag == .obstacle else { return false }
                    let dz = botPos.z - obs.position.z
                    let dx = abs(obs.position.x - x)
                    return dz > 0 && dz <= zRange && dx < 0.4
                }

                if !isBlocked {
                    return x
                }
            }

            return nil
        }
    }


    


    private func isObstacleInFront(of bot: Entity, in obstacles: [Entity], detectionRangeZ: Float = 15, lateralRangeX: Float = 1) -> Bool {
        let botPos = bot.position

        for entity in obstacles {
            let dx = abs(entity.position.x - botPos.x)
            let dz = botPos.z - entity.position.z

            if dz > 0 && dz <= detectionRangeZ && dx <= lateralRangeX {
                return true
            }
        }

        return false
    }

    //BCS:Close
    
    
    private func startBoundaryCheck() {
        boundaryCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.checkPlayerBoundaries()
            self.checkAllEntitiesFinish()
            self.updatePlayerPosition()
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
        print("stop all timers")
//        stopCountdownTimer()
        print("setelah stop")
        playerMovementTimer?.invalidate()  // Invalidate the timer to stop it
        playerMovementTimer = nil  // Reset the timer to release resources
        for (_, botTimer) in botMovementTimers {
                botTimer.invalidate()  // Invalidate each bot's movement timer
            }
        botMovementTimers.removeAll()  // Clear the dictionary
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
    
    //FCS:
    func lockTranslation(for entity: Entity, lockX: Bool = true, lockY: Bool = true, lockZ: Bool = true) {
        guard var physics = entity.components[PhysicsBodyComponent.self] else {
            print("Entity does not have a PhysicsBodyComponent")
            return
        }

        physics.isTranslationLocked = (x: lockX, y: lockY, z: lockZ)
        entity.components.set(physics)
        print("Translation locked - x: \(lockX), y: \(lockY), z: \(lockZ)")
    }

}
    
