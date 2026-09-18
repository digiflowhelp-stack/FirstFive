import SwiftUI
import ARKit
import RealityKit
import UIKit
import ObjectiveC

private var bodySkeleton: BodySkeleton?
private let bodySkeletonAnchor = AnchorEntity()
private var baselineBar: Entity?
private let baselineAnchor = AnchorEntity(.world(transform: simd_float4x4(1)))
private let chairAnchor = AnchorEntity(.world(transform: simd_float4x4(1)))
// Notifications for state changes
extension Notification.Name {
    static let safePositionChanged = Notification.Name("safePositionChanged")
    static let panel3Appeared = Notification.Name("panel3Appeared")
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("Body tracking is not supported on this device.")
        }

        // Your existing body-tracking bootstrapping
        arView.setupForBodyTracking()                // starts ARBodyTrackingConfiguration & sets delegate
        arView.scene.addAnchor(bodySkeletonAnchor)   // your existing body skeleton anchor
        arView.scene.addAnchor(baselineAnchor)       // baseline anchor
        arView.scene.addAnchor(chairAnchor)          // chair anchor for ground positioning

        // Listen for safe position changes
        NotificationCenter.default.addObserver(
            forName: .safePositionChanged,
            object: nil,
            queue: .main
        ) { notification in
            if let inSafePosition = notification.object as? Bool {
                updateBaselineColor(inSafePosition)
            }
        }
        
        // Listen for panel 3 appearance to change EpiPen markers to red
        NotificationCenter.default.addObserver(
            forName: .panel3Appeared,
            object: nil,
            queue: .main
        ) { _ in
            bodySkeleton?.changeEpiPenMarkersToRed()
        }
        
        // Create baseline after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            createBaselineBar()
        }
        
        // Chair 3D model removed per user request
        
        return arView
    }
    
    private func createFixedChair() {
        let chairContainer = Entity()
        
        // Chair materials - much brighter colors
        let brightWoodMaterial = SimpleMaterial(color: UIColor.systemOrange, roughness: 0.2, isMetallic: false)
        let brightCushionMaterial = SimpleMaterial(color: UIColor.systemBlue, roughness: 0.1, isMetallic: false)
        
        // Chair seat
        let seatMesh = MeshResource.generateBox(size: [0.45, 0.05, 0.4], cornerRadius: 0.02)
        let seat = ModelEntity(mesh: seatMesh, materials: [brightCushionMaterial])
        seat.position = [0, 0.4, 0]
        
        // Chair backrest
        let backrestMesh = MeshResource.generateBox(size: [0.45, 0.6, 0.05], cornerRadius: 0.02)
        let backrest = ModelEntity(mesh: backrestMesh, materials: [brightCushionMaterial])
        backrest.position = [0, 0.7, -0.175]
        
        // Chair legs (4 legs)
        let legMesh = MeshResource.generateBox(size: [0.04, 0.4, 0.04], cornerRadius: 0.01)
        
        // Front left leg
        let frontLeftLeg = ModelEntity(mesh: legMesh, materials: [brightWoodMaterial])
        frontLeftLeg.position = [-0.18, 0.2, 0.16]
        
        // Front right leg
        let frontRightLeg = ModelEntity(mesh: legMesh, materials: [brightWoodMaterial])
        frontRightLeg.position = [0.18, 0.2, 0.16]
        
        // Back left leg
        let backLeftLeg = ModelEntity(mesh: legMesh, materials: [brightWoodMaterial])
        backLeftLeg.position = [-0.18, 0.2, -0.16]
        
        // Back right leg
        let backRightLeg = ModelEntity(mesh: legMesh, materials: [brightWoodMaterial])
        backRightLeg.position = [0.18, 0.2, -0.16]
        
        // Add all parts to container
        chairContainer.addChild(seat)
        chairContainer.addChild(backrest)
        chairContainer.addChild(frontLeftLeg)
        chairContainer.addChild(frontRightLeg)
        chairContainer.addChild(backLeftLeg)
        chairContainer.addChild(backRightLeg)
        
        // Apply rotations: 90 degrees anticlockwise + flip
        chairContainer.transform.rotation = simd_quatf(angle: Float.pi / 2, axis: [0, 1, 0])
        
        // Position chair in fixed location: moved slightly left, pushed down to ground
        chairContainer.position = [-0.5, -1.2, -2.0] // Moved left from -0.3 to -0.5, kept Y and Z same
        
        chairAnchor.addChild(chairContainer)
        
        // Make chair disappear after 8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            chairContainer.removeFromParent()
        }
    }
    
    // 3D text removed - now using SwiftUI message panel

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// Small simd helper so we can use .xyz
private extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3<Float>(x, y, z) }
}




extension ARView: ARSessionDelegate {
    func setupForBodyTracking() {
        let config = ARBodyTrackingConfiguration()
        config.frameSemantics = .bodyDetection
        
        // Run the session once here
        session.run(config)
        session.delegate = self
    }

    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                if let skeleton = bodySkeleton {
                    skeleton.update(with: bodyAnchor)
                } else {
                    bodySkeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeletonAnchor.addChild(bodySkeleton!)
                    
                    // Chair is now created immediately in fixed position
                }
            }
        }
    }
}

// Baseline bar functions
private func createBaselineBar() {
    // Create thick horizontal bar
    let barMesh = MeshResource.generateBox(
        size: [3.0, 0.08, 0.02], // Wide, thick, shallow
        cornerRadius: 0.01
    )
    
    // Red transparent material
    let redTransparentMaterial = SimpleMaterial(
        color: UIColor.systemRed.withAlphaComponent(0.7),
        roughness: 0.1,
        isMetallic: false
    )
    let bar = ModelEntity(mesh: barMesh, materials: [redTransparentMaterial])
    
    // Position higher in the scene
    bar.position = [0, -0.7, -1.5] // Higher up, in front of camera
    
    baselineBar = bar
    baselineAnchor.addChild(bar)
}

private func updateBaselineColor(_ inSafePosition: Bool) {
    guard let bar = baselineBar as? ModelEntity else { return }
    
    if inSafePosition {
        // Change bar to green
        let greenMaterial = SimpleMaterial(
            color: UIColor.systemGreen.withAlphaComponent(0.7),
            roughness: 0.1,
            isMetallic: false
        )
        bar.model?.materials = [greenMaterial]
    }
}


// Chair creation moved to BodySkeleton.swift
