//
//  CameraController.swift
//  ChocoRacing
//
//  Created by Muhamad Azis on 20/07/25.
//

import SwiftUI
import RealityKit

class CameraController: ObservableObject {
    
    @Published var followDistance: Float = 3.8 //Jarak dengan character
    @Published var followHeight: Float = 1.0 // Ketinggian kamera
    @Published var followSmoothness: Float = 1

    @Published var lookAtTarget = true
    @Published var isFollowActive = false
    
    private let lockedFollowDistance: Float = 2.5
    private let lockedFollowHeight: Float = 1.5
    private let lockedSmoothness: Float = 0.05
    
    private var cameraEntity: Entity?
    private var targetEntity: Entity?
    
    func setupCamera(content: any RealityViewContentProtocol) {
        let camera = Entity()
        camera.name = "follow_camera"
        
        camera.components.set(PerspectiveCameraComponent(
            near: 1,
            far: 2000.0,
            fieldOfViewInDegrees: 60
        ))
        
        camera.position = SIMD3<Float>(0, followHeight, followDistance)
        
        let cameraAnchor = AnchorEntity()
        cameraAnchor.addChild(camera)
        content.add(cameraAnchor)
        
        self.cameraEntity = camera
        print("✅ Camera setup complete")
    }
    
    func setTarget(_ entity: Entity) {
        self.targetEntity = entity
        print("🎯 Camera target set to: \(entity.name)")
    }
    
    func startFollowing() {
        isFollowActive = true
    }
    
    func stopFollowing() {
        isFollowActive = false
    }
    
    func updateCameraPosition() {
        guard isFollowActive,
              let camera = cameraEntity,
              let target = targetEntity else { return }
        
        let targetPosition = target.position
        var desiredCameraPosition = targetPosition
        
        desiredCameraPosition.z += followDistance
        desiredCameraPosition.y = targetPosition.y + followHeight
        
        let currentPosition = camera.position
        let newPosition = simd_mix(currentPosition, desiredCameraPosition, SIMD3<Float>(repeating: followSmoothness))
        
        let positionDelta = newPosition - currentPosition
        if simd_length(positionDelta) > 0.001 {  
            camera.position = newPosition
        }
        
        if lookAtTarget {
            camera.look(at: targetPosition, from: newPosition, relativeTo: nil)
        }
    }
}
