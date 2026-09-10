import SwiftUI
import ARKit
import RealityKit

struct CardiacArrestView: View {
    @Binding var showHomeScreen: Bool
    @EnvironmentObject var voiceManager: VoiceGuidanceManager
    
    // Current step state
    @State private var currentStep: CPRStep = .positionCheck
    @State private var personIsLyingDown: Bool = false
    @State private var safePositionAchieved: Bool = false
    
    // Panel states
    @State private var showStep1Panel = true
    @State private var showStep2Panel = false
    @State private var showStep3Panel = false
    @State private var showStep5Panel = false
    @State private var step1PanelScale: CGFloat = 1.0
    @State private var step2PanelScale: CGFloat = 1.0
    @State private var step3PanelScale: CGFloat = 1.0
    @State private var step5PanelScale: CGFloat = 1.0
    
    // Animation states
    @State private var showPositionAnimation = false
    @State private var showKneelingAnimation = false
    @State private var showHandPlacementAnimation = false
    @State private var showCompressionAnimation = false
    
    // CPR tracking states
    @State private var chestCompressionMarked = false
    @State private var chestPosition: SIMD3<Float>?
    @State private var compressionCount = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var compressionTimer: Timer?
    @State private var showChestMarker = false
    
    enum CPRStep: String, CaseIterable {
        case positionCheck = "1. Position Check"
        case kneelBeside = "2. Kneel Beside Person"
        case handPlacement = "3. Hand Placement"
        case bodyPosition = "4. Body Position"
        case compressions = "5. Chest Compressions"
        case maintain = "6. Maintain Rhythm"
        
        var instruction: String {
            switch self {
            case .positionCheck:
                return "Ensure person is on their back on firm, flat surface. Roll them over if needed."
            case .kneelBeside:
                return "Kneel beside the person. Position knees near body, shoulder-width apart."
            case .handPlacement:
                return "Place heel of one hand in center of chest, other hand on top. Interlace fingers."
            case .bodyPosition:
                return "Position shoulders directly over hands. Lock elbows, keep arms straight."
            case .compressions:
                return "Push hard and fast - at least 2 inches deep, 100-120 compressions per minute."
            case .maintain:
                return "Allow chest to return to normal position after each compression."
            }
        }
        
        var color: Color {
            switch self {
            case .positionCheck: return .red
            case .kneelBeside: return .orange
            case .handPlacement: return .yellow
            case .bodyPosition: return .green
            case .compressions: return .blue
            case .maintain: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack {
            // AR View
            CardiacArrestARViewContainer(
                currentStep: $currentStep,
                personIsLyingDown: $personIsLyingDown,
                safePositionAchieved: $safePositionAchieved,
                chestPosition: $chestPosition,
                showChestMarker: $showChestMarker
            )
            .edgesIgnoringSafeArea(.all)
            
            // Back button
            VStack {
                HStack {
                    Button(action: {
                        showHomeScreen = true
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    Spacer()
                }
                Spacer()
            }
            
            // Emergency header
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("🫀 CPR")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.9))
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        
                        Text("Chest Compressions")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                    .rotation3DEffect(
                        Angle.degrees(-8),
                        axis: (x: 1.0, y: 0.3, z: 0.0),
                        perspective: 0.6
                    )
                    .position(x: UIScreen.main.bounds.width * 0.3, y: 150)
                }
                Spacer()
            }
            
            // Heart Rate Panel (left side)
            VStack {
                HStack {
                    EnhancedVitalsPanel(isCardiacArrest: true)
                        .frame(width: 200, height: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.3))
                                )
                                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                        )
                        .rotation3DEffect(
                            Angle.degrees(-12),
                            axis: (x: 1.0, y: 0.3, z: 0.0),
                            perspective: 0.6
                        )
                        .position(x: 120, y: 300)
                    Spacer()
                }
                Spacer()
            }
            
            // Step 1: Position Check Panel
            if showStep1Panel {
                CPRStepPanel(
                    title: "1. Position Check",
                    instruction: safePositionAchieved ? "Person is in safe position" : "Ensure person is on their back on firm, flat surface.",
                    status: safePositionAchieved ? "✓ Ready for CPR" : (personIsLyingDown ? "Person lying down" : "Help person lie down"),
                    statusColor: safePositionAchieved ? Color.white : (personIsLyingDown ? Color.yellow : Color.red),
                    backgroundColor: safePositionAchieved ? Color.green : Color.red,
                    icon: "person.fill"
                )
                .frame(width: 340, height: 160)
                .scaleEffect(step1PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        step1PanelScale = 1.08
                    }
                    // Show position animation after 4 second delay, then for 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        showPositionAnimation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            showPositionAnimation = false
                        }
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-15),
                    axis: (x: 1.0, y: 0.2, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 200)
            }
            
            // Step 2: Kneel Beside Person Panel
            if showStep2Panel {
                CPRStepPanel(
                    title: "2. Kneel Beside Person",
                    instruction: "Position knees near person's body, shoulder-width apart",
                    status: "Get into position",
                    statusColor: Color.white,
                    backgroundColor: Color.orange,
                    icon: "figure.walk"
                )
                .frame(width: 340, height: 160)
                .scaleEffect(step2PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        step2PanelScale = 1.06
                    }
                    // Show kneeling animation for 3 seconds
                    showKneelingAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showKneelingAnimation = false
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-12),
                    axis: (x: 1.0, y: 0.2, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 250)
            }
            
            // Step 3: Hand Placement Panel
            if showStep3Panel {
                CPRStepPanel(
                    title: "3. Hand Placement",
                    instruction: "Place hands on top of blue marker. Heel of one hand in center, other hand on top. Interlace fingers.",
                    status: "Position hands on blue marker",
                    statusColor: Color.white,
                    backgroundColor: Color.yellow,
                    icon: "hand.raised.fingers.spread.fill"
                )
                .frame(width: 360, height: 180)
                .scaleEffect(step3PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        step3PanelScale = 1.04
                    }
                    // Show hand placement animation for 4 seconds
                    showHandPlacementAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        showHandPlacementAnimation = false
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-8),
                    axis: (x: 1.0, y: 0.1, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 300)
            }
            
            
            // Step 5: Chest Compressions Panel with Timer
            if showStep5Panel {
                VStack(spacing: 12) {
                    CPRStepPanel(
                        title: "5. Chest Compressions",
                        instruction: "Push hard and fast - at least 2 inches deep",
                        status: "100-120 compressions per minute",
                        statusColor: Color.white,
                        backgroundColor: Color.blue,
                        icon: "heart.circle.fill"
                    )
                    
                    // Compression Counter with Stopwatch
                    VStack(spacing: 8) {
                        Text("Compressions: \(compressionCount)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Time: \(formatElapsedTime(elapsedTime))")
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
                .frame(width: 380, height: 220)
                .scaleEffect(step5PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        step5PanelScale = 1.02
                    }
                    // Show compression animation continuously
                    showCompressionAnimation = true
                }
                .rotation3DEffect(
                    Angle.degrees(-3),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 400)
            }
            
            // Position Animation Overlay (Step 1)
            if showPositionAnimation {
                VStack(spacing: 16) {
                    Text("ROLL TO BACK POSITION")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Person lying down animation
                    ZStack {
                        // Person icon rotating to lying position
                        Image(systemName: "figure.stand")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(showPositionAnimation ? 90 : 0))
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPositionAnimation)
                        
                        // Arrow showing direction
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .offset(x: 60, y: -20)
                            .rotationEffect(.degrees(showPositionAnimation ? 360 : 0))
                            .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: showPositionAnimation)
                    }
                    
                    Text("Flat on firm surface")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red.opacity(0.9))
                        .stroke(Color.white, lineWidth: 3)
                )
                .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .haloVoiceIndicator(voiceManager)
        .preferredColorScheme(.dark)
        .onAppear {
            startCPRWorkflow()
            
            // Auto-trigger safe position after 15 seconds (extra 5 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                if currentStep == .positionCheck && !safePositionAchieved {
                    print("⏰ 10 seconds elapsed - auto-setting safe position")
                    safePositionAchieved = true
                }
            }
        }
        .onChange(of: safePositionAchieved) { _, achieved in
            if achieved && currentStep == .positionCheck {
                print("✅ Safe position achieved! Ready for next step...")
                // Auto-progress after 3 seconds when safe position is achieved
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    progressToStep2()
                }
            }
        }
    }
    
    private func startCPRWorkflow() {
        print("🚨 Starting CPR workflow - Step 1: Position Check")
        currentStep = .positionCheck
        showStep1Panel = true
    }
    
    private func progressToStep2() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .kneelBeside
            showStep1Panel = false
            showStep2Panel = true
        }
        print("🔄 Progressed to Step 2: Kneel Beside Person")
        
        // Auto-progress to Step 3 after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            progressToStep3()
        }
    }
    
    private func progressToStep3() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .handPlacement
            showStep2Panel = false
            showStep3Panel = true
        }
        print("🔄 Progressed to Step 3: Hand Placement")
        
        // Auto-progress to Step 5 after 15 seconds (extra 5 seconds delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            progressToStep5()
        }
    }
    
    private func progressToStep5() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .compressions
            showStep3Panel = false
            showStep5Panel = true
        }
        print("🔄 Progressed to Step 5: Chest Compressions")
        
        // Start compression timer after 2 seconds delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startCompressionTimer()
        }
    }
    
    private func startCompressionTimer() {
        compressionCount = 0
        elapsedTime = 0
        
        // Update every 0.5 seconds for faster, more realistic compression counting
        compressionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            // Update elapsed time every 0.5 seconds
            elapsedTime += 0.5
            
            // Increment compression count every 0.5 seconds (120 compressions per minute)
            compressionCount += 1
        }
        
        print("⏱️ Compression timer started - 120 compressions per minute (every 0.5s)")
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CPRStepPanel: View {
    let title: String
    let instruction: String
    let status: String
    let statusColor: Color
    let backgroundColor: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(instruction)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack {
                Text(status)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(statusColor)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor.opacity(0.8))
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
    }
}

// Private variables for CPR skeleton and markers (like AllergicReactionView)
private var cprBodySkeleton: BodySkeleton?
private let cprBodySkeletonAnchor = AnchorEntity()
private var chestMarker: ModelEntity?
private let chestMarkerAnchor = AnchorEntity(.world(transform: simd_float4x4(1)))

struct CardiacArrestARViewContainer: UIViewRepresentable {
    @Binding var currentStep: CardiacArrestView.CPRStep
    @Binding var personIsLyingDown: Bool
    @Binding var safePositionAchieved: Bool
    @Binding var chestPosition: SIMD3<Float>?
    @Binding var showChestMarker: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("Body tracking is not supported on this device.")
        }

        // Setup exactly like AllergicReactionView
        arView.setupForCPRBodyTracking()
        arView.scene.addAnchor(cprBodySkeletonAnchor)
        arView.scene.addAnchor(chestMarkerAnchor)
        
        // Light blue circle marker will be created when skeleton is detected
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

// Extension for CPR body tracking (exactly like AllergicReactionView)
extension ARView {
    func setupForCPRBodyTracking() {
        let config = ARBodyTrackingConfiguration()
        config.frameSemantics = .bodyDetection
        
        session.run(config)
        session.delegate = CPRSessionDelegate.shared
    }
}

// Separate session delegate for CPR to avoid conflicts
class CPRSessionDelegate: NSObject, ARSessionDelegate {
    static let shared = CPRSessionDelegate()
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                if let skeleton = cprBodySkeleton {
                    skeleton.update(with: bodyAnchor)
                    
                    // Check for chest position and create marker if needed
                    checkForChestMarkerCreation(bodyAnchor: bodyAnchor)
                } else {
                    // Create skeleton exactly like AllergicReactionView but without EpiPen markers
                    cprBodySkeleton = BodySkeleton(for: bodyAnchor, showEpiPenMarkers: false)
                    cprBodySkeletonAnchor.addChild(cprBodySkeleton!)
                    print("🦴 CPR Body skeleton created with bones visible")
                    
                    // IMMEDIATELY create chest marker attached to spine joint
                    attachChestMarkerToSpineJoint(bodyAnchor: bodyAnchor)
                }
            }
        }
    }
}

// Helper function to check chest position and create marker
private func checkForChestMarkerCreation(bodyAnchor: ARBodyAnchor) {
    // Only create marker if it doesn't exist yet
    guard chestMarker == nil else { return }
    
    // Try to find chest joint (spine_7 is upper chest area)
    if let chestJoint = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_7_joint")) ??
                       bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_6_joint")) ??
                       bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_5_joint")) {
        
        let chestPosition = SIMD3<Float>(
            chestJoint.columns.3.x,
            chestJoint.columns.3.y,
            chestJoint.columns.3.z
        )
        
        // Create the chest marker at this position
        createChestCompressionMarker(at: chestPosition)
    }
}


// Function to create chest compression marker (like EpiPen markers but on chest)
private func createChestCompressionMarker() {
    // This will be called after 15 seconds, but we need body position
    // The actual marker creation happens in checkForChestMarkerCreation
    print("⏱️ 15 seconds elapsed - chest marker creation enabled")
}

// IMMEDIATE chest marker creation when skeleton is detected
private func createChestMarkerOnSkeleton(bodyAnchor: ARBodyAnchor) {
    print("🎯 CREATING CHEST MARKER IMMEDIATELY")
    
    // Try multiple chest joints to find the best one
    var chestTransform: simd_float4x4?
    
    if let spine7 = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_7_joint")) {
        chestTransform = spine7
        print("✅ Found spine_7_joint for chest marker")
    } else if let spine6 = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_6_joint")) {
        chestTransform = spine6
        print("✅ Found spine_6_joint for chest marker")
    } else if let spine5 = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_5_joint")) {
        chestTransform = spine5
        print("✅ Found spine_5_joint for chest marker")
    } else if let spine4 = bodyAnchor.skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "spine_4_joint")) {
        chestTransform = spine4
        print("✅ Found spine_4_joint for chest marker")
    }
    
    guard let validTransform = chestTransform else {
        print("❌ NO CHEST JOINT FOUND!")
        return
    }
    
    // Create LARGE red X marker directly on the skeleton
    let xContainer = Entity()
    
    // BRIGHT RED material
    let redMaterial = SimpleMaterial(color: UIColor.red, roughness: 0.0, isMetallic: false)
    
    // Create LARGE X shape - 25cm wide!
    let line1Mesh = MeshResource.generateBox(size: [0.25, 0.04, 0.04], cornerRadius: 0.01)
    let line1Entity = ModelEntity(mesh: line1Mesh, materials: [redMaterial])
    line1Entity.orientation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
    
    let line2Mesh = MeshResource.generateBox(size: [0.25, 0.04, 0.04], cornerRadius: 0.01)
    let line2Entity = ModelEntity(mesh: line2Mesh, materials: [redMaterial])
    line2Entity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1])
    
    // STRONG pulsing animation
    let pulseAnimation = try! AnimationResource.generate(
        with: FromToByAnimation(
            from: Transform(scale: [1.0, 1.0, 1.0]),
            to: Transform(scale: [1.5, 1.5, 1.5]),
            duration: 0.8,
            timing: .easeInOut,
            bindTarget: .transform
        )
    )
    
    line1Entity.playAnimation(pulseAnimation.repeat())
    line2Entity.playAnimation(pulseAnimation.repeat())
    
    xContainer.addChild(line1Entity)
    xContainer.addChild(line2Entity)
    
    // Position directly at chest joint
    let chestPosition = SIMD3<Float>(
        validTransform.columns.3.x,
        validTransform.columns.3.y,
        validTransform.columns.3.z
    )
    
    xContainer.position = chestPosition
    
    // Add directly to skeleton anchor
    cprBodySkeletonAnchor.addChild(xContainer)
    chestMarker = line1Entity
    
    print("❌ LARGE CHEST X MARKER CREATED - 25cm wide, BRIGHT RED, PULSING!")
}

// ATTACH X MARKER DIRECTLY TO SPINE JOINT
private func attachChestMarkerToSpineJoint(bodyAnchor: ARBodyAnchor) {
    print("🎯 ATTACHING X MARKER TO SPINE JOINT")
    
    // Get the skeleton's joint entities from the BodySkeleton
    guard let skeleton = cprBodySkeleton else {
        print("❌ No skeleton found!")
        return
    }
    
    // Try to find spine joint in the skeleton's joints dictionary
    var spineJointEntity: Entity?
    var jointName: String = ""
    
    // Check for spine joints in order of preference (chest area)
    if let spine7Joint = skeleton.joints["spine_7_joint"] {
        spineJointEntity = spine7Joint
        jointName = "spine_7_joint"
        print("✅ Found spine_7_joint entity")
    } else if let spine6Joint = skeleton.joints["spine_6_joint"] {
        spineJointEntity = spine6Joint
        jointName = "spine_6_joint"
        print("✅ Found spine_6_joint entity")
    } else if let spine5Joint = skeleton.joints["spine_5_joint"] {
        spineJointEntity = spine5Joint
        jointName = "spine_5_joint"
        print("✅ Found spine_5_joint entity")
    } else if let spine4Joint = skeleton.joints["spine_4_joint"] {
        spineJointEntity = spine4Joint
        jointName = "spine_4_joint"
        print("✅ Found spine_4_joint entity")
    }
    
    guard let validSpineJoint = spineJointEntity else {
        print("❌ NO SPINE JOINT ENTITY FOUND!")
        return
    }
    
    // Create CIRCLE marker that will be attached directly to the spine joint
    let circleContainer = Entity()
    
    // LIGHT BLUE material
    let lightBlueMaterial = SimpleMaterial(color: UIColor.systemCyan, roughness: 0.1, isMetallic: false)
    
    // Create CIRCLE shape - 15cm diameter
    let circleMesh = MeshResource.generateSphere(radius: 0.075) // 7.5cm radius = 15cm diameter
    let circleEntity = ModelEntity(mesh: circleMesh, materials: [lightBlueMaterial])
    
    // Pulsing animation
    let pulseAnimation = try! AnimationResource.generate(
        with: FromToByAnimation(
            from: Transform(scale: [1.0, 1.0, 1.0]),
            to: Transform(scale: [1.3, 1.3, 1.3]),
            duration: 1.0,
            timing: .easeInOut,
            bindTarget: .transform
        )
    )
    
    circleEntity.playAnimation(pulseAnimation.repeat())
    
    circleContainer.addChild(circleEntity)
    
    // ATTACH DIRECTLY TO THE SPINE JOINT - it will move with the joint!
    validSpineJoint.addChild(circleContainer)
    chestMarker = circleEntity
    
    print("🔵 LIGHT BLUE CIRCLE ATTACHED TO \(jointName) - WILL TRACK CHEST MOVEMENT!")
}

private func createChestCompressionMarker(at position: SIMD3<Float>) {
    print("❌ Creating chest compression X marker at: \(position)")
    
    // Create X-shaped marker for chest compressions (similar to EpiPen markers)
    let markerContainer = Entity()
    
    // Red material for visibility
    let redMaterial = SimpleMaterial(color: UIColor.systemRed, roughness: 0.0, isMetallic: true)
    
    // Create X shape with two diagonal lines
    let line1Mesh = MeshResource.generateBox(size: [0.15, 0.02, 0.02], cornerRadius: 0.005)
    let line1Entity = ModelEntity(mesh: line1Mesh, materials: [redMaterial])
    line1Entity.orientation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
    
    let line2Mesh = MeshResource.generateBox(size: [0.15, 0.02, 0.02], cornerRadius: 0.005)
    let line2Entity = ModelEntity(mesh: line2Mesh, materials: [redMaterial])
    line2Entity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1])
    
    // Add pulsing animation
    let pulseAnimation = try! AnimationResource.generate(
        with: FromToByAnimation(
            from: Transform(scale: [1.0, 1.0, 1.0]),
            to: Transform(scale: [1.3, 1.3, 1.3]),
            duration: 1.0,
            timing: .easeInOut,
            bindTarget: .transform
        )
    )
    
    line1Entity.playAnimation(pulseAnimation.repeat())
    line2Entity.playAnimation(pulseAnimation.repeat())
    
    markerContainer.addChild(line1Entity)
    markerContainer.addChild(line2Entity)
    
    // Position the marker at chest location
    markerContainer.position = position
    
    chestMarkerAnchor.addChild(markerContainer)
    chestMarker = line1Entity
    
    print("❌ Chest compression X marker created - 15cm wide, pulsing red")
}

struct CPRHeartRatePanel: View {
    @State private var heartScale: CGFloat = 1.0
    @State private var currentHeartRate: Int = 85
    private let heartRateValues = [85, 89, 88, 87]
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 12) {
                // Heart icon with pulsing animation
                Image(systemName: "heart.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.red)
                    .scaleEffect(heartScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            heartScale = 1.3
                        }
                        
                        // Start heart rate cycling
                        startHeartRateCycling()
                    }
                
                // Heart rate value - dynamically changing
                Text("\(currentHeartRate) BPM")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            .padding(20)
            
            // Safe range label
            Text("safe range")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.green.opacity(0.8))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.7))
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func startHeartRateCycling() {
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentHeartRate = heartRateValues[currentIndex]
                currentIndex = (currentIndex + 1) % heartRateValues.count
            }
        }
    }
}

struct CardiacArrestView_Previews: PreviewProvider {
    static var previews: some View {
        CardiacArrestView(showHomeScreen: .constant(false))
    }
}
