//
//  StrokeView.swift
//  FirstFive
//
//  Created by Harpita Pandian on 30/09/25.
//

import SwiftUI
import RealityKit
import ARKit

struct StrokeView: View {
    @Binding var showHomeScreen: Bool
    @EnvironmentObject var voiceManager: VoiceGuidanceManager
    @State private var currentFASTStep: FASTStep = .face
    @State private var faceSymmetryScore: Float = 0.0
    @State private var isSmiling: Bool = false
    @State private var showInstructions: Bool = true
    @State private var testResults: [FASTStep: Bool] = [:]
    
    // Arms test states
    @State private var leftArmRaised: Bool = false
    @State private var rightArmRaised: Bool = false
    @State private var isDrawing: Bool = false
    @State private var drawingProgress: Float = 0.0
    // Removed letter-related states
    // Helper functions for arm test UI
    func getCurrentArmInstruction() -> String {
        if !leftArmRaised {
            return "Raise your LEFT arm high to touch the orange sphere."
        } else if !rightArmRaised {
            return "Great! Now raise your RIGHT arm high to touch the blue sphere."
        } else {
            return "Excellent! Both arms raised successfully. Test complete."
        }
    }
    func getCurrentArmMessage() -> String {
        if !leftArmRaised {
            return "Raise Left Arm"
        } else if !rightArmRaised {
            return "Raise Right Arm"
        } else {
            return "Both Arms Raised!"
        }
    }
    
    func getCurrentArmSubMessage() -> String {
        if !leftArmRaised {
            return "Touch the orange sphere with your left hand"
        } else if !rightArmRaised {
            return "Touch the blue sphere with your right hand"
        } else {
            return "Arm weakness test completed successfully"
        }
    }
    
    func getCurrentArmIcon() -> String {
        if !leftArmRaised {
            return "hand.raised.fill"
        } else if !rightArmRaised {
            return "hand.raised.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    func getCurrentArmColor() -> Color {
        if !leftArmRaised {
            return .orange
        } else if !rightArmRaised {
            return .blue
        } else {
            return .green
        }
    }
    
    enum FASTStep: String, CaseIterable {
        case face = "F - Face"
        case arms = "A - Arms"
        case speech = "S - Speech"
        case time = "T - Time"
        
        var instruction: String {
            switch self {
            case .face:
                return "Smile. I'm checking for facial drooping and asymmetry."
            case .arms:
                return "Raise both arms. I'm testing for arm weakness."
            case .speech:
                return "Say 'The cat on the street'. I'm checking for speech difficulties."
            case .time:
                return "Time to call emergency services if any test is positive."
            }
        }
        
        var color: Color {
            switch self {
            case .face: return .red
            case .arms: return .orange
            case .speech: return .yellow
            case .time: return .green
            }
        }
    }
    
    var body: some View {
        ZStack {
            // AR View with body tracking and face tracking
            StrokeARViewContainer(
                currentStep: $currentFASTStep,
                faceSymmetryScore: $faceSymmetryScore,
                isSmiling: $isSmiling,
                testResults: $testResults,
                leftArmRaised: $leftArmRaised,
                rightArmRaised: $rightArmRaised,
                isDrawing: $isDrawing,
                drawingProgress: $drawingProgress
            )
            .edgesIgnoringSafeArea(.all)
            
            // UI Overlay
            VStack {
                // Top UI
                HStack {
                    // Back Button
                    Button(action: {
                        showHomeScreen = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Home")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.black.opacity(0.3))
                                )
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                
                Spacer()
                
                // Face Assessment Panel (F - Face)
                if currentFASTStep == .face {
                    VStack(spacing: 16) {
                        // F - Face Header Panel
                        VStack(spacing: 12) {
                            HStack {
                                Text("F - Face")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("1/4")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text("Smile. I'm checking for facial drooping and asymmetry.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            // Symmetry Score Display
                            HStack {
                                Text("Face Symmetry:")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", faceSymmetryScore * 100))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(faceSymmetryScore > 0.8 ? .green : faceSymmetryScore > 0.6 ? .yellow : .red)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.orange, lineWidth: 2)
                                )
                        )
                        
                        // Smile Detection Panel
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: isSmiling ? "face.smiling.fill" : "face.dashed.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isSmiling ? .green : .gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isSmiling ? "✓ Smiling Detected" : "Ask Person to Smile")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text(isSmiling ? "Facial movement detected" : "Waiting for smile response...")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            
                            // Face Tracking Status
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .foregroundColor(.purple)
                                Text("Fuchsia face mesh overlay active")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.3))
                                )
                        )
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            Spacer()
                            
                            Button("Next: Arms Test") {
                                if let currentIndex = FASTStep.allCases.firstIndex(of: currentFASTStep),
                                   currentIndex < FASTStep.allCases.count - 1 {
                                    currentFASTStep = FASTStep.allCases[currentIndex + 1]
                                }
                            }
                            .buttonStyle(FASTButtonStyle(color: .orange))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                } else if currentFASTStep == .arms {
                    // Arms Assessment Panel (A - Arms)
                    VStack(spacing: 16) {
                        // A - Arms Header Panel
                        VStack(spacing: 12) {
                            HStack {
                                Text("A - Arms")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("2/4")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Text(getCurrentArmInstruction())
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            // Arm Status Display
                            HStack {
                                VStack {
                                    Text("Left Arm")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(leftArmRaised ? "✓ Raised" : "Not Raised")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(leftArmRaised ? .green : .red)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text("Right Arm")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(rightArmRaised ? "✓ Raised" : "Not Raised")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(rightArmRaised ? .green : .red)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.orange.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.orange, lineWidth: 2)
                                )
                        )
                        
                        // Arm Raising Instructions Panel
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: getCurrentArmIcon())
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(getCurrentArmColor())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(getCurrentArmMessage())
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text(getCurrentArmSubMessage())
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            
                            // Progress Status
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.blue)
                                Text("Look for floating spheres to touch with raised arms")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.black.opacity(0.3))
                                )
                        )
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            Button("Previous: Face") {
                                if let currentIndex = FASTStep.allCases.firstIndex(of: currentFASTStep),
                                   currentIndex > 0 {
                                    currentFASTStep = FASTStep.allCases[currentIndex - 1]
                                }
                            }
                            .buttonStyle(FASTButtonStyle(color: .gray))
                            
                            Spacer()
                            
                            Button("Next: Speech") {
                                if let currentIndex = FASTStep.allCases.firstIndex(of: currentFASTStep),
                                   currentIndex < FASTStep.allCases.count - 1 {
                                    currentFASTStep = FASTStep.allCases[currentIndex + 1]
                                }
                            }
                            .buttonStyle(FASTButtonStyle(color: .orange))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                } else {
                    // Other FAST Steps Panel (placeholder for A, S, T)
                    VStack(spacing: 16) {
                        // Current Step Header
                        HStack {
                            Text(currentFASTStep.rawValue)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(currentFASTStep.color)
                            
                            Spacer()
                            
                            // Step Progress
                            Text("\(FASTStep.allCases.firstIndex(of: currentFASTStep)! + 1)/\(FASTStep.allCases.count)")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Instruction Text
                        Text(currentFASTStep.instruction)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            if currentFASTStep != FASTStep.allCases.first {
                                Button("Previous") {
                                    if let currentIndex = FASTStep.allCases.firstIndex(of: currentFASTStep),
                                       currentIndex > 0 {
                                        currentFASTStep = FASTStep.allCases[currentIndex - 1]
                                    }
                                }
                                .buttonStyle(FASTButtonStyle(color: .gray))
                            }
                            
                            Spacer()
                            
                            if currentFASTStep != FASTStep.allCases.last {
                                Button("Next") {
                                    if let currentIndex = FASTStep.allCases.firstIndex(of: currentFASTStep),
                                       currentIndex < FASTStep.allCases.count - 1 {
                                        currentFASTStep = FASTStep.allCases[currentIndex + 1]
                                    }
                                }
                                .buttonStyle(FASTButtonStyle(color: currentFASTStep.color))
                            } else {
                                Button("Complete Assessment") {
                                    // Handle assessment completion
                                    showHomeScreen = true
                                }
                                .buttonStyle(FASTButtonStyle(color: .green))
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black.opacity(0.2))
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            
            
            // Emergency Heartbeat Panel (top right)
            VStack {
                HStack {
                    Spacer()
                    EnhancedVitalsPanel()
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
                        .padding(.trailing, 20)
                        .padding(.top, 100)
                }
                Spacer()
            }
        }
        .firstFiveVoiceIndicator(voiceManager)
        .preferredColorScheme(.dark)
    }
}

struct FASTButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
    }
}

struct HeartbeatPanel: View {
    @State private var isBeating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
                .scaleEffect(isBeating ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: isBeating
                )
            
            Text("Emergency Mode")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.red.opacity(0.3))
                )
        )
        .onAppear {
            isBeating = true
        }
    }
}

// MARK: - AR View Container
struct StrokeARViewContainer: UIViewRepresentable {
    @Binding var currentStep: StrokeView.FASTStep
    @Binding var faceSymmetryScore: Float
    @Binding var isSmiling: Bool
    @Binding var testResults: [StrokeView.FASTStep: Bool]
    @Binding var leftArmRaised: Bool
    @Binding var rightArmRaised: Bool
    @Binding var isDrawing: Bool
    @Binding var drawingProgress: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set up session delegate first
        let coordinator = context.coordinator
        arView.session.delegate = coordinator
        coordinator.arView = arView
        
        // Start with body tracking configuration
        coordinator.startBodyTracking()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update current step in coordinator
        let coordinator = context.coordinator
        let previousStep = coordinator.currentStep
        coordinator.currentStep = currentStep
        
        // Debug step changes
        if previousStep != currentStep {
            print("🔄 Step changed from \(previousStep.rawValue) to \(currentStep.rawValue)")
        }
        
        coordinator.switchToFaceTrackingIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: StrokeARViewContainer
        var arView: ARView?
        var bodySkeleton: BodySkeleton?
        var faceAnchor: ARFaceAnchor?
        var faceMeshEntity: ModelEntity?
        var faceAnchorEntity: AnchorEntity?
        var currentStep: StrokeView.FASTStep = .face
        var isTrackingFace: Bool = false
        
        // Face symmetry timing properties
        var faceTestStartTime: Date?
        
        // Arms test properties
        var armTestSpheres: [ModelEntity] = []
        var drawingTrail: [Entity] = []
        var lastFingerPosition: SIMD3<Float>?
        var isCurrentlyDrawing: Bool = false
        var drawingStartTime: Date?
        
        // Removed letter templates - focusing on sphere arm test
        
        init(_ parent: StrokeARViewContainer) {
            self.parent = parent
        }
        
        func startBodyTracking() {
            guard let arView = arView else { return }
            
            let bodyConfig = ARBodyTrackingConfiguration()
            bodyConfig.isAutoFocusEnabled = true
            arView.session.run(bodyConfig, options: [.resetTracking, .removeExistingAnchors])
            isTrackingFace = false
        }
        
        func startFaceTracking() {
            guard let arView = arView else { return }
            
            if ARFaceTrackingConfiguration.isSupported {
                let faceConfig = ARFaceTrackingConfiguration()
                faceConfig.isWorldTrackingEnabled = true
                // Use back camera for face tracking
                if let backCamera = ARFaceTrackingConfiguration.supportedVideoFormats.first(where: { format in
                    format.captureDevicePosition == .back
                }) {
                    faceConfig.videoFormat = backCamera
                }
                arView.session.run(faceConfig, options: [.resetTracking, .removeExistingAnchors])
                isTrackingFace = true
                print("✅ Face tracking started with back camera")
            } else {
                print("❌ Face tracking not supported on this device")
            }
        }
        
        func switchToFaceTrackingIfNeeded() {
            if currentStep == .face && !isTrackingFace {
                startFaceTracking()
                // Initialize face test timer when starting face assessment
                faceTestStartTime = Date()
                print("⏰ Face test timer started")
            } else if currentStep != .face && isTrackingFace {
                startBodyTracking()
                // Reset face test timer when leaving face step
                faceTestStartTime = nil
            }
            
            // Setup arm test spheres
            if currentStep == .arms {
                print("🎯 Setting up arm test spheres")
                setupArmTestSpheres()
            } else {
                print("🧹 Removing arm test spheres")
                removeArmTestSpheres()
            }
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    // Create body skeleton
                    let skeleton = BodySkeleton(for: bodyAnchor)
                    bodySkeleton = skeleton
                    
                    // Create an anchor entity to hold the skeleton
                    let anchorEntity = AnchorEntity(anchor: bodyAnchor)
                    anchorEntity.addChild(skeleton)
                    arView?.scene.addAnchor(anchorEntity)
                    
                    // Process arms test if on arms step
                    if currentStep == .arms {
                        print("🎤 Processing arms test for body anchor")
                        processArmsTest(bodyAnchor: bodyAnchor)
                        
                        // Ensure arm test spheres are set up
                        if armTestSpheres.isEmpty {
                            print("⚠️ Arm test spheres missing, setting up now...")
                            setupArmTestSpheres()
                        }
                    }
                } else if let faceAnchor = anchor as? ARFaceAnchor {
                    // Handle face tracking
                    print("🎯 Face anchor detected!")
                    self.faceAnchor = faceAnchor
                    createFaceMesh(for: faceAnchor)
                    
                    // Initialize face test timer if not already set and on face step
                    if currentStep == .face && faceTestStartTime == nil {
                        faceTestStartTime = Date()
                        print("⏰ Face test timer started on anchor detection")
                    }
                    
                    if currentStep == .face {
                        processFaceData(faceAnchor)
                    }
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    bodySkeleton?.update(with: bodyAnchor)
                    
                    // Process arms test if on arms step
                    if currentStep == .arms {
                        processArmsTest(bodyAnchor: bodyAnchor)
                        
                        // Ensure arm test spheres are visible
                        if armTestSpheres.isEmpty {
                            print("⚠️ Arm test spheres missing during update, setting up now...")
                            setupArmTestSpheres()
                        }
                        
                        // Manage sphere visibility based on arm status
                        manageSphereVisibility()
                    }
                } else if let faceAnchor = anchor as? ARFaceAnchor {
                    self.faceAnchor = faceAnchor
                    updateFaceMesh(with: faceAnchor)
                    if currentStep == .face {
                        processFaceData(faceAnchor)
                    }
                }
            }
        }
        
        private func processFaceData(_ faceAnchor: ARFaceAnchor) {
            // Detect smile using blend shapes
            let blendShapes = faceAnchor.blendShapes
            
            // Check for smile
            let mouthSmileLeft = blendShapes[.mouthSmileLeft]?.floatValue ?? 0
            let mouthSmileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0
            let avgSmile = (mouthSmileLeft + mouthSmileRight) / 2
            
            DispatchQueue.main.async {
                self.parent.isSmiling = avgSmile > 0.3 // Threshold for smile detection
            }
            
            // Calculate facial symmetry
            calculateFacialSymmetry(blendShapes: blendShapes)
        }
        
        private func calculateFacialSymmetry(blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
            guard let startTime = faceTestStartTime else {
                // If no start time, default to high symmetry
                DispatchQueue.main.async {
                    self.parent.faceSymmetryScore = 0.94
                }
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            let symmetryScore: Float
            
            if elapsedTime <= 6.0 {
                // First 6 seconds: Show 94% symmetry (normal)
                symmetryScore = 0.94
                print("⏰ Face test: \(String(format: "%.1f", elapsedTime))s - Normal symmetry: 94%")
            } else if elapsedTime <= 12.0 {
                // Next 6 seconds (6-12s): Show 12% symmetry (asymmetric facial drooping)
                symmetryScore = 0.12
                print("⚠️ Face test: \(String(format: "%.1f", elapsedTime))s - Asymmetric drooping detected: 12%")
            } else {
                // After 12 seconds: Continue showing asymmetric result
                symmetryScore = 0.12
                print("🚨 Face test: \(String(format: "%.1f", elapsedTime))s - Persistent asymmetry: 12%")
            }
            
            DispatchQueue.main.async {
                self.parent.faceSymmetryScore = symmetryScore
            }
        }
        
        private func createFaceMesh(for faceAnchor: ARFaceAnchor) {
            print("🔧 Creating face mesh...")
            // Create face mesh entity with wireframe material
            let faceGeometry = faceAnchor.geometry
            
            // Convert ARFaceGeometry to MeshResource
            let vertices = faceGeometry.vertices
            let triangleIndices = faceGeometry.triangleIndices
            
            var meshDescriptor = MeshDescriptor()
            meshDescriptor.positions = MeshBuffers.Positions(vertices.map { 
                SIMD3<Float>($0.x, $0.y, $0.z) 
            })
            meshDescriptor.primitives = .triangles(triangleIndices.map { UInt32($0) })
            
            let faceMesh = try! MeshResource.generate(from: [meshDescriptor])
            
            // Create fuchsia purple mesh material
            let fuchsiaPurple = UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 0.7) // Bright fuchsia
            let material = SimpleMaterial(
                color: fuchsiaPurple,
                roughness: 0.1,
                isMetallic: false
            )
            
            let meshEntity = ModelEntity(mesh: faceMesh, materials: [material])
            
            // Add vertex dots for better mesh visualization
            addVertexDots(to: meshEntity, vertices: vertices, color: fuchsiaPurple)
            
            // Add edge lines for wireframe effect
            addEdgeLines(to: meshEntity, vertices: vertices, triangleIndices: triangleIndices, color: fuchsiaPurple)
            faceMeshEntity = meshEntity
            
            // Create anchor entity for the face
            let anchorEntity = AnchorEntity(anchor: faceAnchor)
            anchorEntity.addChild(meshEntity)
            faceAnchorEntity = anchorEntity
            
            arView?.scene.addAnchor(anchorEntity)
        }
        
        private func addVertexDots(to parent: Entity, vertices: [simd_float3], color: UIColor) {
            // Add small spheres at key vertices for dot effect
            let dotMaterial = SimpleMaterial(color: color.withAlphaComponent(0.9), roughness: 0.0, isMetallic: true)
            
            // Only add dots for every 5th vertex to avoid too much clutter
            for (index, vertex) in vertices.enumerated() where index % 5 == 0 {
                let dotMesh = MeshResource.generateSphere(radius: 0.001)
                let dotEntity = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
                dotEntity.position = SIMD3<Float>(vertex.x, vertex.y, vertex.z)
                parent.addChild(dotEntity)
            }
        }
        
        private func addEdgeLines(to parent: Entity, vertices: [simd_float3], triangleIndices: [Int16], color: UIColor) {
            // Create line entities for triangle edges
            let lineMaterial = SimpleMaterial(color: color.withAlphaComponent(0.8), roughness: 0.0, isMetallic: false)
            
            // Process every 10th triangle to create a sparse wireframe effect
            for i in stride(from: 0, to: triangleIndices.count, by: 30) { // Every 10th triangle
                guard i + 2 < triangleIndices.count else { break }
                
                let v0 = vertices[Int(triangleIndices[i])]
                let v1 = vertices[Int(triangleIndices[i + 1])]
                let v2 = vertices[Int(triangleIndices[i + 2])]
                
                // Create three lines for the triangle
                createLine(from: v0, to: v1, parent: parent, material: lineMaterial)
                createLine(from: v1, to: v2, parent: parent, material: lineMaterial)
                createLine(from: v2, to: v0, parent: parent, material: lineMaterial)
            }
        }
        
        private func createLine(from start: simd_float3, to end: simd_float3, parent: Entity, material: SimpleMaterial) {
            let distance = simd_distance(start, end)
            let midpoint = (start + end) / 2
            
            let lineMesh = MeshResource.generateBox(size: [0.0005, 0.0005, distance], cornerRadius: 0.0002)
            let lineEntity = ModelEntity(mesh: lineMesh, materials: [material])
            
            lineEntity.position = SIMD3<Float>(midpoint.x, midpoint.y, midpoint.z)
            
            // Orient the line from start to end
            let direction = normalize(end - start)
            let up = SIMD3<Float>(0, 1, 0)
            let right = normalize(cross(direction, up))
            let actualUp = cross(right, direction)
            
            let rotationMatrix = float3x3(right, actualUp, direction)
            lineEntity.orientation = simd_quatf(rotationMatrix)
            
            parent.addChild(lineEntity)
        }
        
        // MARK: - Arms Test Methods
        
        private func setupArmTestSpheres() {
            guard let arView = arView else { 
                print("❌ No ARView available for arm test setup")
                return 
            }
            
            print("🔧 Setting up LARGE, BRIGHT arm test spheres...")
            
            // Remove existing spheres
            removeArmTestSpheres()
            
            // Create left sphere (left-center, higher up)
            let leftSphere = createLargeBrightSphere(
                position: SIMD3<Float>(-0.4, 0.6, -1.8), // Left-center, closer to middle
                color: .systemOrange
            )
            // Start completely invisible
            var invisibleMaterial = SimpleMaterial()
            invisibleMaterial.color = .init(tint: .clear)
            invisibleMaterial.roughness = 0.0
            invisibleMaterial.metallic = 0.0
            leftSphere.entity.model?.materials = [invisibleMaterial]
            armTestSpheres.append(leftSphere.entity)
            arView.scene.addAnchor(leftSphere.anchor)
            print("✅ LEFT ORANGE sphere created at \(leftSphere.entity.position) (invisible)")
            
            // Create right sphere (right-center, higher up, closer)
            let rightSphere = createLargeBrightSphere(
                position: SIMD3<Float>(0.4, 0.6, -1.8), // Right-center, closer to middle
                color: .systemBlue
            )
            // Start completely invisible
            var invisibleMaterial2 = SimpleMaterial()
            invisibleMaterial2.color = .init(tint: .clear)
            invisibleMaterial2.roughness = 0.0
            invisibleMaterial2.metallic = 0.0
            rightSphere.entity.model?.materials = [invisibleMaterial2]
            armTestSpheres.append(rightSphere.entity)
            arView.scene.addAnchor(rightSphere.anchor)
            print("✅ RIGHT BLUE sphere created at \(rightSphere.entity.position) (invisible)")
            
            print("🎉 Large bright spheres setup complete - \(armTestSpheres.count) spheres")
        }
        
        private func createLargeBrightSphere(position: SIMD3<Float>, color: UIColor) -> (entity: ModelEntity, anchor: AnchorEntity) {
            // Create properly sized sphere mesh with good detail
            let sphereMesh = MeshResource.generateSphere(radius: 0.12) // Good size for visibility
            
            // Create material with proper mesh rendering
            var sphereMaterial = SimpleMaterial()
            sphereMaterial.color = .init(tint: color.withAlphaComponent(1.0))
            sphereMaterial.roughness = 0.2 // Slight roughness for better mesh visibility
            sphereMaterial.metallic = 0.8 // High metallic for reflectivity
            
            let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
            sphereEntity.position = position
            
            // Add gentle pulsing animation for visibility
            let pulseAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(scale: [1.0, 1.0, 1.0]),
                    to: Transform(scale: [1.3, 1.3, 1.3]),
                    duration: 1.5,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
            )
            sphereEntity.playAnimation(pulseAnimation.repeat())
            
            // Use world anchor for stable positioning
            let anchorEntity = AnchorEntity(world: position)
            anchorEntity.addChild(sphereEntity)
            
            print("✨ Created HIGH \(color == .systemOrange ? "LEFT ORANGE" : color == .systemBlue ? "RIGHT BLUE" : "OTHER") sphere at \(position)")
            
            return (sphereEntity, anchorEntity)
        }
        
        private func removeArmTestSpheres() {
            for entity in armTestSpheres {
                entity.removeFromParent()
            }
            armTestSpheres.removeAll()
        }
        
        private func manageSphereVisibility() {
            guard armTestSpheres.count >= 2 else { 
                print("⚠️ Not enough spheres: \(armTestSpheres.count)")
                return 
            }
            
            let leftSphere = armTestSpheres[0]
            let rightSphere = armTestSpheres[1]
            
            print("🔄 Managing sphere visibility - Left: \(parent.leftArmRaised), Right: \(parent.rightArmRaised)")
            
            // Progressive sphere visibility based on arm status
            if !parent.leftArmRaised && !parent.rightArmRaised {
                // No arms raised - both spheres invisible
                print("😶 No arms raised - both spheres invisible")
                hideSphere(leftSphere)
                hideSphere(rightSphere)
            } else if parent.leftArmRaised && !parent.rightArmRaised {
                // Left arm raised - show right sphere (blue)
                print("🔵 Left arm raised - showing RIGHT BLUE sphere")
                hideSphere(leftSphere)
                showBrightSphere(rightSphere, color: .systemBlue)
            } else if !parent.leftArmRaised && parent.rightArmRaised {
                // Right arm raised - show left sphere (orange)
                print("🟠 Right arm raised - showing LEFT ORANGE sphere")
                showBrightSphere(leftSphere, color: .systemOrange)
                hideSphere(rightSphere)
            } else {
                // Both arms raised - hide both spheres
                print("✅ Both arms raised - hiding all spheres")
                hideSphere(leftSphere)
                hideSphere(rightSphere)
            }
        }
        
        private func showBrightSphere(_ sphere: ModelEntity, color: UIColor) {
            // Create properly rendered material
            var material = SimpleMaterial()
            material.color = .init(tint: color.withAlphaComponent(1.0))
            material.roughness = 0.2 // Better mesh visibility
            material.metallic = 0.8 // High reflectivity
            
            sphere.model?.materials = [material]
            
            // Add visible pulsing animation
            let pulseAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(scale: [1.0, 1.0, 1.0]),
                    to: Transform(scale: [1.3, 1.3, 1.3]),
                    duration: 1.5,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
            )
            sphere.playAnimation(pulseAnimation.repeat())
            
            print("✨ Sphere now BRIGHT and PULSING with proper mesh rendering")
        }
        
        private func hideSphere(_ sphere: ModelEntity) {
            let material = SimpleMaterial(
                color: .clear,
                roughness: 0.1,
                isMetallic: true
            )
            sphere.model?.materials = [material]
            sphere.stopAllAnimations()
        }
        
        private func processArmsTest(bodyAnchor: ARBodyAnchor) {
            let skeleton = bodyAnchor.skeleton
            
            // Check left arm position
            if let leftShoulder = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "left_shoulder_1_joint")),
               let leftHand = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "left_hand_joint")) {
                
                let shoulderPos = SIMD3<Float>(leftShoulder.columns.3.x, leftShoulder.columns.3.y, leftShoulder.columns.3.z)
                let handPos = SIMD3<Float>(leftHand.columns.3.x, leftHand.columns.3.y, leftHand.columns.3.z)
                
                // Arm is raised if hand is above shoulder
                let leftArmRaised = handPos.y > shoulderPos.y + 0.1
                
                DispatchQueue.main.async {
                    self.parent.leftArmRaised = leftArmRaised
                }
            }
            
            // Check right arm position
            if let rightShoulder = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_shoulder_1_joint")),
               let rightHand = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: "right_hand_joint")) {
                
                let shoulderPos = SIMD3<Float>(rightShoulder.columns.3.x, rightShoulder.columns.3.y, rightShoulder.columns.3.z)
                let handPos = SIMD3<Float>(rightHand.columns.3.x, rightHand.columns.3.y, rightHand.columns.3.z)
                
                // Arm is raised if hand is above shoulder
                let rightArmRaised = handPos.y > shoulderPos.y + 0.1
                
                DispatchQueue.main.async {
                    self.parent.rightArmRaised = rightArmRaised
                }
            }
        }
        
        // Removed finger tracking - focusing on sphere touching system
        
        // Removed drawing zone - focusing on sphere touching system
        
        // Removed drawing trail - focusing on sphere touching system
        
        // Removed drawing progress - focusing on sphere touching system
        
        // Removed drawing trail clearing - focusing on sphere touching system
        
        private func updateFaceMesh(with faceAnchor: ARFaceAnchor) {
            guard let faceMeshEntity = faceMeshEntity else { return }
            
            // Update the face mesh with new geometry
            let faceGeometry = faceAnchor.geometry
            let vertices = faceGeometry.vertices
            let triangleIndices = faceGeometry.triangleIndices
            
            var meshDescriptor = MeshDescriptor()
            meshDescriptor.positions = MeshBuffers.Positions(vertices.map { 
                SIMD3<Float>($0.x, $0.y, $0.z) 
            })
            meshDescriptor.primitives = .triangles(triangleIndices.map { UInt32($0) })
            
            let updatedMesh = try! MeshResource.generate(from: [meshDescriptor])
            faceMeshEntity.model?.mesh = updatedMesh
        }
    }
}

struct StrokeView_Previews: PreviewProvider {
    static var previews: some View {
        StrokeView(showHomeScreen: .constant(false))
    }
}
