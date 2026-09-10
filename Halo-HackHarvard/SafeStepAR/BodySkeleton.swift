//  BodySkeleton.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 28/09/25.
//

import Foundation
import RealityKit
import ARKit
import UIKit   // ensure UIColor is available

class BodySkeleton: Entity {
    var joints: [String: Entity] = [:]
    var bones: [String: Entity] = [:]
    var epiPenMarkers: [Entity] = []
    private var epiPenMarkersVisible: Bool = false
    private var epiPenMarkersRed: Bool = false
    var baselineDottedLine: Entity?
    // Chair is now handled in ARViewContainer
    
    // Posture detection properties
    private var isLyingDown: Bool = false
    private let lyingDownThreshold: Float = 0.3  // Y-axis threshold for lying down detection
    private var isInSafePosition: Bool = false
    
    // Public property to access posture state
    var personIsLyingDown: Bool {
        return isLyingDown
    }
    
    // Heatmap color helper based on joint group + tiny per-joint variation
    private func heatmapColor(for jointName: String) -> UIColor {
        // Group base hues (0...1): red→orange→yellow/green→cyan→blue→magenta
        let baseHue: CGFloat = {
            let n = jointName
            // Head / face / neck
            if n.contains("head") || n.contains("neck_") || n.contains("jaw") || n.contains("chin")
                || n.contains("eye") || n.contains("nose") || n.contains("ear") {
                return 0.00 // red
            }
            // Spine / torso / hips
            if n.hasPrefix("spine_") || n.contains("hips") || n.contains("pelvis") || n.contains("chest") {
                return 0.08 // red→orange
            }
            // Shoulders / upper arms
            if n.contains("shoulder") || n.contains("upperarm") {
                return 0.14 // orange→yellow
            }
            // Forearms / hands / fingers
            if n.contains("forearm") || n.contains("hand") || n.contains("thumb") || n.contains("index")
                || n.contains("middle") || n.contains("ring") || n.contains("little") {
                return 0.52 // cyan-ish
            }
            // Upper legs / thighs
            if n.contains("upleg") || n.contains("upperleg") || n.contains("thigh") {
                return 0.72 // blue→violet
            }
            // Lower legs / feet / toes
            if n.contains("leg") || n.contains("knee") || n.contains("foot") || n.contains("toes") || n.contains("ankle") {
                return 0.83 // magenta
            }
            return 0.0 // fallback: red
        }()
        
        // Small deterministic per-joint hue variation for a subtle gradient within the group
        let sum = jointName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let variation = CGFloat((sum % 12)) / 120.0  // up to ~0.10
        let hue = fmod(baseHue + variation, 1.0)
        return UIColor(hue: hue, saturation: 0.90, brightness: 1.0, alpha: 1.0)
    }
    
    // Helper function to determine which joints to hide
    private func shouldHideJoint(_ jointName: String) -> Bool {
        // Hide most hand joints to reduce clutter
        if jointName.hasPrefix("left_hand") && jointName != "left_hand_joint" {
            return true
        }
        if jointName.hasPrefix("right_hand") && jointName != "right_hand_joint" {
            return true
        }
        
        // Hide neck and head joints above neck
        if jointName.contains("neck_") || jointName == "head_joint" ||
           jointName.contains("jaw") || jointName.contains("chin") ||
           jointName.contains("eye") || jointName.contains("nose") {
            return true
        }
        
        return false
    }

    init(for bodyAnchor: ARBodyAnchor, showEpiPenMarkers: Bool = true) {
        super.init()
        
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            // Smaller default joint balls (mocap vibe)
            var jointRadius: Float = 0.02
            let jointColor: UIColor = heatmapColor(for: jointName)

            // Size tweaks by joint type (color stays heatmap)
            switch jointName {
            case "neck_1_joint", "neck_2_joint", "neck_3_joint", "neck_4_joint",
                 "head_joint", "left_shoulder_1_joint", "right_shoulder_1_joint":
                jointRadius *= 0.75

            case "jaw_joint", "chin_joint",
                 "left_eye_joint", "left_eyeLowerLid_joint", "left_eyeUpperLid_joint", "left_eyeball_joint",
                 "nose_joint",
                 "right_eye_joint", "right_eyeLowerLid_joint", "right_eyeUpperLid_joint", "right_eyeball_joint":
                jointRadius *= 0.45

            case _ where jointName.hasPrefix("spine_"):
                jointRadius *= 0.9

            case "left_hand_joint", "right_hand_joint":
                jointRadius *= 0.6

            case _ where jointName.hasPrefix("left_toes") || jointName.hasPrefix("right_toes"):
                break
            default:
                break
            }
            
            let jointEntity = createJointEntity(radius: jointRadius, color: jointColor)
            joints[jointName] = jointEntity
            self.addChild(jointEntity)
        }
        
        // Create bone entities for each tracked bone using Bones enum
        for bone in Bones.allCases {
            guard let _ = joints[bone.jointFromName],
                  let _ = joints[bone.jointToName],
                  let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor) else { continue }
            
            let boneEntity = createBoneEntity(for: skeletonBone)
            bones[bone.name] = boneEntity
            self.addChild(boneEntity)
        }
        
        // Only create EpiPen markers if requested (for allergic reaction view)
        if showEpiPenMarkers {
            // Create EpiPen injection site markers at upper thighs after 20 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                self.createEpiPenMarkers()
            }
        }
        
        // Chair is now created immediately in ARViewContainer
        // Baseline is now handled in ARViewContainer
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    func update(with bodyAnchor: ARBodyAnchor) {
        // Align BodySkeleton with bodyAnchor (root at hipJoint)
        self.setTransformMatrix(bodyAnchor.transform, relativeTo: nil)
        
        // Update transform for each tracked jointEntity
        for jointName in ARSkeletonDefinition.defaultBody3D.jointNames {
            if let jointEntity = joints[jointName],
               let jointEntityTransform = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                jointEntity.setTransformMatrix(jointEntityTransform, relativeTo: self)
            }
        }
        
        for bone in Bones.allCases {
            let boneName = bone.name
            
            guard let entity = bones[boneName],
                  let skeletonBone = createSkeletonBone(bone: bone, bodyAnchor: bodyAnchor)
            else { continue }
            
            entity.position = skeletonBone.centerPosition
            entity.look(at: skeletonBone.toJoint.position, from: skeletonBone.centerPosition, relativeTo: nil) // set orientation for bone
        }
        
        // Update posture detection
        updatePostureDetection()
        
        // Update EpiPen markers
        updateEpiPenMarkers()
        
        // Chair positioning removed - now fixed in ARViewContainer
    }
    
    private func createJointEntity(radius: Float, color: UIColor = .white) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: color, roughness: 0.8, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    private func createSkeletonBone(bone: Bones, bodyAnchor: ARBodyAnchor) -> SkeletonBone? {
        guard let fromJointEntity = joints[bone.jointFromName],
              let toJointEntity = joints[bone.jointToName]
        else { return nil }
        
        // Get world-space positions
        let fromPosition = fromJointEntity.position(relativeTo: nil)
        let toPosition = toJointEntity.position(relativeTo: nil)
        
        // Create skeleton joints
        let fromJoint = SkeletonJoint(name: bone.jointFromName, position: fromPosition)
        let toJoint = SkeletonJoint(name: bone.jointToName, position: toPosition)
        
        // Create and return skeleton bone
        return SkeletonBone(fromJoint: fromJoint, toJoint: toJoint)
    }
    
    private func createBoneEntity(for skeletonBone: SkeletonBone,
                                  diameter: Float = 0.005,            // thinner line bones
                                  color: UIColor = UIColor.systemYellow) -> Entity {
        let mesh = MeshResource.generateBox(size: [diameter, diameter, skeletonBone.length],
                                            cornerRadius: diameter / 2)
        let material = SimpleMaterial(color: color, roughness: 0.2, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    // MARK: - Posture Detection
    private func updatePostureDetection() {
        // Get key joints for better posture detection
        guard let headJoint = joints["head_joint"],
              let hipsJoint = joints["hips_joint"] else { return }
        
        let headPosition = headJoint.position(relativeTo: nil)
        let hipsPosition = hipsJoint.position(relativeTo: nil)
        
        // Calculate spine vector (from hips to head)
        let spineVector = headPosition - hipsPosition
        
        // Standing: spine is mostly vertical (Y-axis dominant)
        // Lying down: spine is mostly horizontal (X or Z axis dominant)
        let verticalComponent = abs(spineVector.y)
        let horizontalComponent = sqrt(spineVector.x * spineVector.x + spineVector.z * spineVector.z)
        
        // Person is lying down if horizontal component is greater than vertical
        // Add some threshold to avoid jittery transitions
        let lyingDownRatio: Float = 0.7 // If horizontal/vertical > 0.7, person is lying down
        isLyingDown = horizontalComponent > (verticalComponent * lyingDownRatio)
    }
    
    // MARK: - EpiPen Injection Site Marker
    private func createEpiPenMarkers() {
        // Create marker for ONE thigh (right thigh)
        guard let rightThighJoint = joints["right_upLeg_joint"] else { return }
        
        let marker = createEpiPenXMarker()
        marker.position = [0, -0.1, 0] // Slightly below the joint
        rightThighJoint.addChild(marker)
        epiPenMarkers.append(marker)
        epiPenMarkersVisible = true
    }
    
    private func createEpiPenXMarker() -> Entity {
        let container = Entity()
        
        // Create two crossed bars to form a much larger, bright green X
        let barLength: Float = 0.25  // Even larger
        let barThickness: Float = 0.04  // Much thicker
        
        // Dynamic color material - green initially, can change to red
        let markerColor = epiPenMarkersRed ? UIColor.systemRed : UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 1.0)
        let markerMaterial = SimpleMaterial(color: markerColor, roughness: 0.1, isMetallic: false)
        
        // First bar (diagonal /)
        let bar1Mesh = MeshResource.generateBox(
            size: [barLength, barThickness, barThickness],
            cornerRadius: barThickness / 3
        )
        let bar1 = ModelEntity(mesh: bar1Mesh, materials: [markerMaterial])
        bar1.transform.rotation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
        
        // Second bar (diagonal \)
        let bar2Mesh = MeshResource.generateBox(
            size: [barLength, barThickness, barThickness],
            cornerRadius: barThickness / 3
        )
        let bar2 = ModelEntity(mesh: bar2Mesh, materials: [markerMaterial])
        bar2.transform.rotation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1])
        
        container.addChild(bar1)
        container.addChild(bar2)
        
        // Add white 3D arrow pointing to the X
        let arrow = createWhiteArrow()
        arrow.position = [0, 0.15, 0] // Position above the X marker
        container.addChild(arrow)
        
        // Stronger pulsing animation for larger X
        let scaleAnimation = try! AnimationResource.generate(
            with: FromToByAnimation(
                from: Transform(scale: [1.0, 1.0, 1.0]),
                to: Transform(scale: [1.4, 1.4, 1.4]),
                duration: 1.2,
                timing: .easeInOut,
                bindTarget: .transform
            )
        )
        let pulseAnimation = scaleAnimation.repeat()
        container.playAnimation(pulseAnimation)
        
        return container
    }
    
    private func createWhiteArrow() -> Entity {
        let arrowContainer = Entity()
        
        // Arrow shaft (vertical line pointing down)
        let shaftMesh = MeshResource.generateBox(
            size: [0.01, 0.08, 0.01],
            cornerRadius: 0.005
        )
        let whiteMaterial = SimpleMaterial(color: .white, roughness: 0.1, isMetallic: false)
        let shaft = ModelEntity(mesh: shaftMesh, materials: [whiteMaterial])
        
        // Arrow head (triangle pointing down)
        let headMesh = MeshResource.generateBox(
            size: [0.03, 0.02, 0.01],
            cornerRadius: 0.005
        )
        let head = ModelEntity(mesh: headMesh, materials: [whiteMaterial])
        head.position = [0, -0.05, 0] // Position at bottom of shaft
        head.transform.rotation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
        
        // Second part of arrow head
        let head2 = ModelEntity(mesh: headMesh, materials: [whiteMaterial])
        head2.position = [0, -0.05, 0]
        head2.transform.rotation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1])
        
        arrowContainer.addChild(shaft)
        arrowContainer.addChild(head)
        arrowContainer.addChild(head2)
        
        return arrowContainer
    }
    
    private func updateEpiPenMarkers() {
        // Markers are attached to joints, so they update automatically
        // Only update if markers are visible
        if !epiPenMarkersVisible {
            return
        }
    }
    
    private func createBaselineDottedLine() {
        let lineContainer = Entity()
        
        // Create thick horizontal bar (not dotted)
        let barMesh = MeshResource.generateBox(
            size: [3.0, 0.05, 0.02], // Wide, thick, shallow
            cornerRadius: 0.01
        )
        
        // Red transparent material
        let redTransparentMaterial = SimpleMaterial(
            color: UIColor.systemRed.withAlphaComponent(0.7),
            roughness: 0.1,
            isMetallic: false
        )
        let bar = ModelEntity(mesh: barMesh, materials: [redTransparentMaterial])
        
        // Position in center of screen, slightly lower than center
        // Fixed position in world space (not anchored to skeleton)
        bar.position = [0, -0.3, -1.5] // Slightly below center, in front of camera
        
        lineContainer.addChild(bar)
        baselineDottedLine = lineContainer
        
        // Don't add to skeleton - add to scene directly with fixed position
        // This will be handled in ARViewContainer
    }
    
    private func startBaselineBlinking() {
        guard let baseline = baselineDottedLine else { return }
        
        // Blinking animation - appear/disappear every 1.5 seconds
        let blinkAnimation = try! AnimationResource.generate(
            with: FromToByAnimation(
                from: Transform(scale: [1.0, 1.0, 1.0]),
                to: Transform(scale: [0.0, 0.0, 0.0]),
                duration: 0.75,
                timing: .easeInOut,
                bindTarget: .transform
            )
        )
        let repeatBlinkAnimation = blinkAnimation.repeat()
        baseline.playAnimation(repeatBlinkAnimation)
    }
    
    private func updateBaselineDottedLine() {
        guard let baseline = baselineDottedLine else { return }
        
        // Position the baseline above the legs
        if let leftAnkle = joints["left_ankle_joint"],
           let rightAnkle = joints["right_ankle_joint"] {
            
            let leftPos = leftAnkle.position(relativeTo: self)
            let rightPos = rightAnkle.position(relativeTo: self)
            
            // Position baseline slightly above the ankles
            let centerX = (leftPos.x + rightPos.x) / 2
            let centerZ = (leftPos.z + rightPos.z) / 2
            let baselineY = max(leftPos.y, rightPos.y) + 0.15 // 15cm above ankles
            
            baseline.position = [centerX, baselineY, centerZ]
        }
        
        // Change color to green when in safe position
        if isInSafePosition {
            updateBaselineColor(to: .systemGreen)
        }
    }
    
    private func updateBaselineColor(to color: UIColor) {
        guard let baseline = baselineDottedLine else { return }
        
        let greenMaterial = SimpleMaterial(color: color, roughness: 0.1, isMetallic: false)
        
        for child in baseline.children {
            if let modelEntity = child as? ModelEntity {
                modelEntity.model?.materials = [greenMaterial]
            }
        }
        
        // Stop blinking when green
        if color == .systemGreen {
            baseline.stopAllAnimations()
            baseline.transform.scale = [1.0, 1.0, 1.0] // Ensure it's visible
        }
    }
    
    // Public method to set safe position state
    func setInSafePosition(_ inSafePosition: Bool) {
        isInSafePosition = inSafePosition
        if inSafePosition {
            updateBaselineColor(to: .systemGreen)
        }
    }
    
    // Public method to change EpiPen marker color to red
    func changeEpiPenMarkersToRed() {
        epiPenMarkersRed = true
        // Recreate markers with new color if they exist
        if epiPenMarkersVisible {
            // Remove old markers
            for marker in epiPenMarkers {
                marker.removeFromParent()
            }
            epiPenMarkers.removeAll()
            
            // Create new red markers
            createEpiPenMarkers()
        }
    }
    
    // Chair functions moved to ARViewContainer for fixed positioning
    

}
