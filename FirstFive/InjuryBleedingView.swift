//
//  InjuryBleedingView.swift
//  FirstFive
//
//  Created by Harpita Pandian on 01/10/25.
//

import SwiftUI
import RealityKit
import ARKit

struct InjuryBleedingView: View {
    @Binding var showHomeScreen: Bool
    @EnvironmentObject var voiceManager: VoiceGuidanceManager
    @State private var currentStep: TourniquetStep = .tapWound
    @State private var woundMarked: Bool = false
    @State private var woundPosition: SIMD3<Float>?
    @State private var snapRingPosition: SIMD3<Float>?
    @State private var snapRingValid: Bool = false
    @State private var jointWarning: String?
    @State private var showWrappingArrows: Bool = false
    
    // Removed all materials state variables that were causing AR conflicts
    
    // Panel progression states - Steps 1, 2, 3, 4, and 5
    @State private var showStep1Panel = true
    @State private var showStep2Panel = false
    @State private var showStep3Panel = false
    @State private var showStep4Panel = false
    @State private var showStep5Panel = false
    
    // Panel animation states - Steps 1, 2, 3, 4, and 5
    @State private var step1PanelScale: CGFloat = 1.0
    @State private var step2PanelScale: CGFloat = 1.0
    @State private var step3PanelScale: CGFloat = 1.0
    @State private var step4PanelScale: CGFloat = 1.0
    @State private var step5PanelScale: CGFloat = 1.0
    
    // Timer state for Step 5
    @State private var tourniquetStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    // Animation overlay states
    @State private var showPressureAnimation = false
    @State private var showTwistAnimation = false
    
    enum TourniquetStep: String, CaseIterable {
        case tapWound = "1. Mark Bleeding Site"
        case autoZone = "2. Apply Direct Pressure"
        case gatherMaterials = "3. Apply Tourniquet Above Wound"
        case ghostWrap = "4. Insert Windlass Rod"
        case windlass = "5. Tourniquet Timer Active"
        case secure = "6. Secure & Timestamp"
        case verify = "7. Verification"
        
        var instruction: String {
            switch self {
            case .tapWound:
                return "Identify bleeding point on arm."
            case .autoZone:
                return "Apply firm direct pressure to control bleeding with clean cloth."
            case .gatherMaterials:
                return "Apply tourniquet 2-3 inches above wound site until pulse stops below."
            case .ghostWrap:
                return "Insert rigid rod/stick through tourniquet. Tie overhand knot to secure windlass."
            case .windlass:
                return "Rotate windlass clockwise until bleeding ceases. Secure rod with fabric loops."
            case .secure:
                return "Lock the windlass and tie off securely."
            case .verify:
                return "Check bleeding and distal pulse."
            }
        }
        
        var color: Color {
            switch self {
            case .tapWound: return .red
            case .autoZone: return .orange
            case .gatherMaterials: return .yellow
            case .ghostWrap: return .green
            case .windlass: return .blue
            case .secure: return .purple
            case .verify: return .pink
            }
        }
    }
    
    var body: some View {
        ZStack {
            // AR View with body tracking and wound marking
            InjuryBleedingARViewContainer(
                currentStep: $currentStep,
                woundMarked: $woundMarked,
                woundPosition: $woundPosition,
                snapRingPosition: $snapRingPosition,
                snapRingValid: $snapRingValid,
                jointWarning: $jointWarning,
                showWrappingArrows: $showWrappingArrows
            )
            .edgesIgnoringSafeArea(.all)
            
            // Back Button (top-left)
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
            .position(x: 80, y: 60)
            
            // Enhanced Vitals Panel (top-left)
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
                .rotation3DEffect(
                    Angle.degrees(15),
                    axis: (x: 1.0, y: 0.3, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.3, y: 150)
            
            // Step 1: Tap to Mark Wound Panel (top-right)
            if showStep1Panel {
                TourniquetStepPanel(
                    title: "1. Mark Bleeding Site",
                    instruction: "Identify bleeding point on arm",
                    status: woundMarked ? "✓ Wound Site Located" : "Locate active bleeding",
                    statusColor: woundMarked ? Color.green : Color.red,
                    backgroundColor: Color.red,
                    icon: "location.fill"
                )
                .frame(width: 320, height: 150)
                .scaleEffect(step1PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        step1PanelScale = 1.08
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-15),
                    axis: (x: 1.0, y: 0.2, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 200)
            }
            
            // Step 2: Auto Zone Detection Panel (top-right)
            if showStep2Panel {
                TourniquetStepPanel(
                    title: "2. Apply Direct Pressure",
                    instruction: "Apply firm pressure to bleeding site with clean cloth",
                    status: "Hold pressure for 5 seconds",
                    statusColor: Color.white,
                    backgroundColor: Color.blue,
                    icon: "hand.raised.fill"
                )
                .frame(width: 320, height: 150)
                .scaleEffect(step2PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        step2PanelScale = 1.06
                    }
                    // Show pressure animation for 3 seconds
                    showPressureAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showPressureAnimation = false
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-10),
                    axis: (x: 1.0, y: 0.1, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 350)
                .transition(.scale)
            }
            
            // Step 3: Tie Around Blue Line Panel (top-right)
            if showStep3Panel {
                TourniquetStepPanel(
                    title: "3. Apply Tourniquet Above Wound",
                    instruction: "Find blue marker 2-3 inches above wound. Tie KNOT with cloth to make makeshift tourniquet",
                    status: "Wrap tight - Stop pulse below",
                    statusColor: Color.white,
                    backgroundColor: Color.black,
                    icon: "bandage.fill"
                )
                .frame(width: 340, height: 160)
                .scaleEffect(step3PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                        step3PanelScale = 1.05
                    }
                    // Start tourniquet timer immediately when Step 3 appears
                    startTourniquetTimer()
                }
                .rotation3DEffect(
                    Angle.degrees(-5),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: 0.6
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 500)
                .transition(.scale)
            }
            
            
            // Step 5: Tourniquet Timer (large overlay above blue line)
            if showStep5Panel {
                VStack(spacing: 8) {
                    Text("TOURNIQUET APPLIED")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.9))
                        )
                    
                    Text("Time: \(formatElapsedTime(elapsedTime))")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                                .stroke(Color.red, lineWidth: 3)
                        )
                    
                    Text("Critical: Notify EMS of tourniquet time")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(step5PanelScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        step5PanelScale = 1.03
                    }
                    // Timer already started in Step 3
                }
                .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height - 150)
                .transition(.scale)
            }
            
            // Pressure Animation Overlay (Step 2)
            if showPressureAnimation {
                VStack(spacing: 16) {
                    Text("APPLY PRESSURE")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Two hands crossed over each other animation
                    ZStack {
                        // Hand 1
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-15))
                            .offset(x: -20, y: 0)
                            .scaleEffect(showPressureAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showPressureAnimation)
                        
                        // Hand 2 (crossed over)
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.8))
                            .rotationEffect(.degrees(15))
                            .offset(x: 20, y: 10)
                            .scaleEffect(showPressureAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showPressureAnimation)
                    }
                    
                    Text("Hold firmly for 5 seconds")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.9))
                        .stroke(Color.white, lineWidth: 3)
                )
                .position(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.4)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Twist Animation Overlay (Step 4)
            if showTwistAnimation {
                VStack(spacing: 16) {
                    Text("TWIST CLOCKWISE")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Rotating arrow showing clockwise direction
                    ZStack {
                        // Circular arrow
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.orange)
                            .rotationEffect(.degrees(showTwistAnimation ? 360 : 0))
                            .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: showTwistAnimation)
                        
                        // Rod/stick icon in center
                        Rectangle()
                            .fill(Color.brown)
                            .frame(width: 6, height: 40)
                            .cornerRadius(3)
                    }
                    
                    Text("Until bleeding stops")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.yellow)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.green.opacity(0.9))
                        .stroke(Color.white, lineWidth: 3)
                )
                .position(x: UIScreen.main.bounds.width * 0.25, y: UIScreen.main.bounds.height * 0.4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .firstFiveVoiceIndicator(voiceManager)
        .preferredColorScheme(.dark)
        .onAppear {
            startTourniquetWorkflow()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: woundMarked) { _, marked in
            print("🔄 Wound marked changed to: \(marked), current step: \(currentStep.rawValue)")
            if marked && currentStep == .tapWound {
                print("🎯 X marker placed! Step 1 panel stays visible for 2 seconds...")
                // Keep Step 1 panel visible - don't hide it immediately
                
                // Auto-progress to step 2 when wound is marked
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    progressToStep2()
                }
            }
        }
        // Removed snapRingValid onChange - Step 2 now progresses automatically after 5 seconds
        .onChange(of: currentStep) { _, newStep in
            // Trigger AR updates when step changes
            print("🔄 Current step changed to: \(newStep.rawValue)")
        }
        // Removed materialsReady onChange to prevent AR conflicts
    }
    
    // Sequential workflow for tourniquet application
    private func startTourniquetWorkflow() {
        // Step 1 panel is already visible
        print("🩸 Starting tourniquet application workflow")
    }
    
    private func progressToStep2() {
        print("🔄 Starting Step 2: Apply Pressure - PRESERVING ALL AR ELEMENTS")
        print("🎯 Wound position available: \(woundPosition != nil)")
        print("🎯 Wound marked: \(woundMarked)")
        
        // CRITICAL: Only update UI state, do NOT touch AR elements
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .autoZone
            showStep1Panel = false  // Hide Step 1 panel when Step 2 starts
            showStep2Panel = true
        }
        
        // IMPORTANT: Do NOT create or modify any AR elements during Step 2
        // The X marker should remain visible from Step 1
        // The blue line will be created ONLY when Step 3 starts
        
        print("✅ Step 2 panel shown - X marker should remain visible")
        print("🔴 Apply pressure phase - no AR modifications")
        
        // Auto-progress to Step 3 after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            self.progressToStep3()
        }
    }
    
    private func progressToStep4() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .ghostWrap
            showStep4Panel = true
        }
        print("🔄 Progressed to Step 4: Insert Windlass Rod")
    }
    
    private func progressToStep5() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .windlass
            showStep5Panel = true
        }
        print("🔄 Progressed to Step 5: Tourniquet Timer Active")
    }
    
    private func startTourniquetTimer() {
        tourniquetStartTime = Date()
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = tourniquetStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
        
        print("⏱️ Tourniquet timer started - critical for EMS handoff")
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Direct ring creation function
    private func createSnapRingDirectly(at position: SIMD3<Float>) {
        print("🔵 Creating snap ring directly at position: \(position)")
        // This will be handled by the AR coordinator through binding updates
    }
    
    // Create wrapping arrows function
    private func createWrappingArrows(at position: SIMD3<Float>) {
        print("🔄 Creating rotating wrapping arrows at position: \(position)")
        showWrappingArrows = true
    }
    
    private func progressToStep3() {
        withAnimation(.easeInOut(duration: 0.8)) {
            currentStep = .gatherMaterials
            showStep3Panel = true
        }
        print("🔄 Progressed to Step 3: Tie Around Blue Line")
        
        // NOW create the blue line for Step 3
        if let woundPos = woundPosition {
            // Calculate safe zone position 2-3 inches (6-8cm) above wound
            let safeZonePosition = SIMD3<Float>(woundPos.x, woundPos.y + 0.07, woundPos.z) // 7cm = ~2.75 inches
            
            // Set state for blue line creation
            snapRingPosition = safeZonePosition
            snapRingValid = true
            jointWarning = nil
            
            print("🔵 Creating blue line for Step 3 at: \(safeZonePosition)")
            
            // Create the blue line immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.createSnapRingDirectly(at: safeZonePosition)
            }
            
            // Auto-progress to Step 5 (Timer) after 10 seconds - skip windlass step
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.progressToStep5()
            }
        }
    }
    
    // Removed checkMaterialsReady function that was causing AR conflicts
}

struct TourniquetStepPanel: View {
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

// Removed MaterialsGatheringPanel, WidthRulerOverlay, and RulerButtonStyle
// These components were causing AR session conflicts and are no longer needed

struct TourniquetButtonStyle: ButtonStyle {
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

struct EmergencyHeartbeatPanel: View {
    @State private var isBeating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "drop.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
                .scaleEffect(isBeating ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: isBeating
                )
            
            Text("Bleeding Emergency")
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
struct InjuryBleedingARViewContainer: UIViewRepresentable {
    @Binding var currentStep: InjuryBleedingView.TourniquetStep
    @Binding var woundMarked: Bool
    @Binding var woundPosition: SIMD3<Float>?
    @Binding var snapRingPosition: SIMD3<Float>?
    @Binding var snapRingValid: Bool
    @Binding var jointWarning: String?
    @Binding var showWrappingArrows: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Set up session delegate
        let coordinator = context.coordinator
        arView.session.delegate = coordinator
        coordinator.arView = arView
        
        // Add tap gesture for wound marking
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Start body tracking
        coordinator.startARSession()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let coordinator = context.coordinator
        let previousStep = coordinator.currentStep
        coordinator.currentStep = currentStep
        
        // Handle step transitions
        if previousStep != currentStep {
            print("🔄 Step changed from \(previousStep.rawValue) to \(currentStep.rawValue)")
            coordinator.handleStepTransition(from: previousStep, to: currentStep)
        }
        
        // Handle snap ring creation when position is set
        if let ringPos = snapRingPosition, coordinator.snapRingAnchor == nil {
            print("🎯 Snap ring position detected, creating ring at: \(ringPos)")
            coordinator.createSnapRingDirectly(at: ringPos)
        }
        
        // Handle wrapping arrows creation when showWrappingArrows becomes true
        if showWrappingArrows && coordinator.wrappingArrowsAnchor == nil {
            if let ringPos = snapRingPosition {
                print("🔄 Creating rotating wrapping arrows around blue line")
                coordinator.createRotatingWrappingArrows(at: ringPos)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: InjuryBleedingARViewContainer
        var arView: ARView?
        var bodySkeleton: BodySkeleton?
        var currentStep: InjuryBleedingView.TourniquetStep = .tapWound
        var woundMarker: ModelEntity?
        var woundAnchor: AnchorEntity?
        var snapRing: ModelEntity?
        var snapRingAnchor: AnchorEntity?
        var wrappingArrows: [ModelEntity] = []
        var wrappingArrowsAnchor: AnchorEntity?
        
        init(_ parent: InjuryBleedingARViewContainer) {
            self.parent = parent
        }
        
        func startARSession() {
            guard let arView = arView else { return }
            
            // Use simple world tracking instead of body tracking
            let config = ARWorldTrackingConfiguration()
            config.isAutoFocusEnabled = true
            config.planeDetection = [.horizontal, .vertical]
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            print("✅ AR World tracking started for injury & bleeding assessment")
        }
        
        func handleStepTransition(from previousStep: InjuryBleedingView.TourniquetStep, to newStep: InjuryBleedingView.TourniquetStep) {
            print("🔄 AR Coordinator handling step transition: \(previousStep.rawValue) → \(newStep.rawValue)")
            
            switch newStep {
            case .autoZone:
                // Step 2: Apply Pressure - DO NOT modify AR elements
                print("🔴 Step 2: Apply Pressure - preserving X marker, no new AR elements")
                // Do nothing - keep X marker visible
            case .gatherMaterials:
                // Step 3: Create blue line for tying
                if parent.woundMarked, let woundPos = parent.woundPosition {
                    print("🔵 Step 3: Creating blue line for cloth tying")
                    let safeZonePos = SIMD3<Float>(woundPos.x, woundPos.y + 0.05, woundPos.z)
                    createSnapRing(woundPosition: safeZonePos)
                }
            default:
                // Don't remove anything - keep all AR elements visible
                print("🔄 Keeping all AR elements visible")
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard currentStep == .tapWound, !parent.woundMarked else { 
                print("⚠️ Tap ignored - currentStep: \(currentStep), woundMarked: \(parent.woundMarked)")
                return 
            }
            
            let location = gesture.location(in: arView)
            print("🎯 Tap detected at screen location: \(location)")
            
            // Convert screen tap to world position using raycast
            if let arView = arView {
                // Try raycast to find a surface
                if let raycastResult = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
                    let worldPosition = raycastResult.worldTransform.columns.3
                    let tapPosition = SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z)
                    print("✅ Raycast hit at world position: \(tapPosition)")
                    
                    createWoundMarkerAtTapLocation(at: tapPosition)
                    
                    DispatchQueue.main.async {
                        self.parent.woundMarked = true
                        self.parent.woundPosition = tapPosition
                    }
                } else {
                    // If no surface detected, place marker 1 meter in front of camera
                    let cameraTransform = arView.cameraTransform
                    let cameraPosition = cameraTransform.translation
                    let cameraForward = -cameraTransform.matrix.columns.2
                    let markerPosition = cameraPosition + normalize(SIMD3<Float>(cameraForward.x, cameraForward.y, cameraForward.z)) * 1.0
                    
                    print("⚠️ No surface detected, placing marker in front of camera at: \(markerPosition)")
                    createWoundMarkerAtTapLocation(at: markerPosition)
                    
                    DispatchQueue.main.async {
                        self.parent.woundMarked = true
                        self.parent.woundPosition = markerPosition
                    }
                }
            }
        }
        
        private func isNearLegArea(position: SIMD3<Float>) -> Bool {
            // Basic validation - check if position is in reasonable leg area
            // This is a simplified check - in a real app you'd use more sophisticated body part detection
            return position.y > -1.0 && position.y < 0.5 && abs(position.x) < 1.0
        }
        
        private func createWoundMarkerAtTapLocation(at position: SIMD3<Float>) {
            guard let arView = arView else {
                print("❌ No ARView available for wound marker creation")
                return
            }
            
            print("🔧 Creating X-shaped wound marker at tap location: \(position)")
            
            // Remove existing marker if any
            removeWoundMarker()
            
            // Create X-shaped wound marker at exact tap location
            let anchorEntity = AnchorEntity(world: position)
            
            // Create red material for X marker
            var xMaterial = SimpleMaterial()
            xMaterial.color = .init(tint: UIColor.systemRed)
            xMaterial.roughness = 0.0
            xMaterial.metallic = 1.0
            
            // First line of X (diagonal) - SMALLER SIZE
            let line1Mesh = MeshResource.generateBox(size: [0.08, 0.015, 0.015], cornerRadius: 0.003)
            let line1Entity = ModelEntity(mesh: line1Mesh, materials: [xMaterial])
            line1Entity.orientation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1])
            
            // Second line of X (diagonal) - SMALLER SIZE
            let line2Mesh = MeshResource.generateBox(size: [0.08, 0.015, 0.015], cornerRadius: 0.003)
            let line2Entity = ModelEntity(mesh: line2Mesh, materials: [xMaterial])
            line2Entity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1])
            
            // Add subtle pulsing animation
            let pulseAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(scale: [1.0, 1.0, 1.0]),
                    to: Transform(scale: [1.2, 1.2, 1.2]),
                    duration: 1.2,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
            )
            
            line1Entity.playAnimation(pulseAnimation.repeat())
            line2Entity.playAnimation(pulseAnimation.repeat())
            
            // Add only the X components to anchor (no blood drip)
            anchorEntity.addChild(line1Entity)
            anchorEntity.addChild(line2Entity)
            
            // Add to AR scene
            arView.scene.addAnchor(anchorEntity)
            
            woundMarker = line1Entity
            woundAnchor = anchorEntity
            
            print("❌ Smaller X-shaped wound marker created at tap location")
            print("📏 X marker size: 8cm x 1.5cm - clean and visible")
            print("🔴 No blood drip - clean marker only")
        }
        
        private func createWoundMarker(at position: SIMD3<Float>) {
            guard let arView = arView else { 
                print("❌ No ARView available for wound marker creation")
                return 
            }
            
            print("🔧 Creating X-shaped wound marker at position: \(position)")
            
            // Remove existing marker if any
            removeWoundMarker()
            
            // Create X-shaped wound marker using two crossing boxes
            let anchorEntity = AnchorEntity(world: position)
            
            // Create red material for X marker
            var xMaterial = SimpleMaterial()
            xMaterial.color = .init(tint: UIColor.systemRed)
            xMaterial.roughness = 0.0
            xMaterial.metallic = 1.0
            
            // First line of X (diagonal)
            let line1Mesh = MeshResource.generateBox(size: [0.08, 0.01, 0.01], cornerRadius: 0.002)
            let line1Entity = ModelEntity(mesh: line1Mesh, materials: [xMaterial])
            line1Entity.orientation = simd_quatf(angle: Float.pi / 4, axis: [0, 0, 1]) // 45 degree rotation
            
            // Second line of X (diagonal)
            let line2Mesh = MeshResource.generateBox(size: [0.08, 0.01, 0.01], cornerRadius: 0.002)
            let line2Entity = ModelEntity(mesh: line2Mesh, materials: [xMaterial])
            line2Entity.orientation = simd_quatf(angle: -Float.pi / 4, axis: [0, 0, 1]) // -45 degree rotation
            
            // Add pulsing animation to both lines
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
            
            // Add blood drip effect below X
            let dripMesh = MeshResource.generateSphere(radius: 0.015)
            var dripMaterial = SimpleMaterial()
            dripMaterial.color = .init(tint: UIColor.systemRed.withAlphaComponent(0.8))
            dripMaterial.roughness = 0.1
            dripMaterial.metallic = 0.7
            
            let dripEntity = ModelEntity(mesh: dripMesh, materials: [dripMaterial])
            dripEntity.position = SIMD3<Float>(0, -0.08, 0) // Below X marker
            
            // Add drip animation
            let dripAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(translation: [0, -0.08, 0]),
                    to: Transform(translation: [0, -0.15, 0]),
                    duration: 2.0,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
            )
            dripEntity.playAnimation(dripAnimation.repeat())
            
            // Add all components to anchor
            anchorEntity.addChild(line1Entity)
            anchorEntity.addChild(line2Entity)
            anchorEntity.addChild(dripEntity)
            
            woundMarker = line1Entity // Store reference to first line
            woundAnchor = anchorEntity
            arView.scene.addAnchor(anchorEntity)
            
            print("❌ X-shaped wound marker created with pulsing animation and blood drip")
            print("📍 Marker anchored at arm position: \(position)")
            print("🩸 Ready for arm tourniquet application")
        }
        
        private func removeWoundMarker() {
            if woundMarker != nil || woundAnchor != nil {
                print("🧹 Removing existing wound marker")
                woundMarker?.removeFromParent()
                woundAnchor?.removeFromParent()
                woundMarker = nil
                woundAnchor = nil
            }
        }
        
        func createSnapRingDirectly(at position: SIMD3<Float>) {
            print("🔵 Direct snap ring creation at: \(position)")
            createSnapRing(woundPosition: position)
        }
        
        func createRotatingWrappingArrows(at position: SIMD3<Float>) {
            guard let arView = arView else {
                print("❌ No ARView available for wrapping arrows creation")
                return
            }
            
            print("🔄 Creating rotating wrapping arrows around blue line at: \(position)")
            
            // Remove existing arrows if any
            removeWrappingArrows()
            
            // Find the body anchor to attach the arrows
            guard let bodyAnchor = arView.scene.anchors.compactMap({ $0 as? AnchorEntity }).first?.children.first?.parent as? AnchorEntity else {
                print("❌ Could not find body anchor for wrapping arrows")
                return
            }
            
            // Create arrows container entity
            let arrowsEntity = Entity()
            arrowsEntity.position = position
            
            // Create orange material for arrows (indicating wrapping direction)
            var arrowMaterial = SimpleMaterial()
            arrowMaterial.color = .init(tint: UIColor.systemOrange)
            arrowMaterial.roughness = 0.0
            arrowMaterial.metallic = 1.0
            
            // Create 6 arrows in a circle around the blue line
            let numArrows = 6
            let radius: Float = 0.08 // Slightly larger than blue line
            
            for i in 0..<numArrows {
                let angle = Float(i) * (2.0 * Float.pi / Float(numArrows))
                let arrowX = cos(angle) * radius
                let arrowZ = sin(angle) * radius
                
                // Create arrow shape (pointing in clockwise direction)
                let arrowMesh = MeshResource.generateBox(size: [0.03, 0.008, 0.015], cornerRadius: 0.002)
                let arrowEntity = ModelEntity(mesh: arrowMesh, materials: [arrowMaterial])
                
                // Position arrow
                arrowEntity.position = SIMD3<Float>(arrowX, 0, arrowZ)
                
                // Rotate arrow to point clockwise (tangent to circle)
                let tangentAngle = angle + Float.pi / 2 // 90 degrees ahead for clockwise
                arrowEntity.orientation = simd_quatf(angle: tangentAngle, axis: [0, 1, 0])
                
                // Add to arrows array and container
                wrappingArrows.append(arrowEntity)
                arrowsEntity.addChild(arrowEntity)
            }
            
            // Create continuous rotation animation (clockwise)
            let rotationAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(rotation: simd_quatf(angle: 0, axis: [0, 1, 0])),
                    to: Transform(rotation: simd_quatf(angle: 2 * Float.pi, axis: [0, 1, 0])),
                    duration: 3.0, // 3 seconds per full rotation
                    timing: .linear,
                    bindTarget: .transform
                )
            )
            
            // Apply rotation to the entire arrows container
            arrowsEntity.playAnimation(rotationAnimation.repeat())
            
            // Anchor to body skeleton
            bodyAnchor.addChild(arrowsEntity)
            
            wrappingArrowsAnchor = bodyAnchor
            
            print("🔄 Created 6 rotating orange arrows showing clockwise wrapping direction")
            print("⭕ Arrows rotating around blue line to demonstrate cloth wrapping")
        }
        
        private func removeWrappingArrows() {
            if !wrappingArrows.isEmpty || wrappingArrowsAnchor != nil {
                print("🧹 Removing wrapping arrows")
                for arrow in wrappingArrows {
                    arrow.removeFromParent()
                }
                wrappingArrows.removeAll()
                wrappingArrowsAnchor = nil
            }
        }
        
        private func createSnapRing(woundPosition: SIMD3<Float>) {
            guard let arView = arView else {
                print("❌ No ARView available for safe zone creation")
                return
            }
            
            print("🔧 Creating safe zone line above X marker")
            
            // Remove existing safe zone if any
            removeSnapRing()
            
            // Find the body anchor to attach the safe zone line
            guard let bodyAnchor = arView.scene.anchors.compactMap({ $0 as? AnchorEntity }).first?.children.first?.parent as? AnchorEntity else {
                print("❌ Could not find body anchor for safe zone")
                return
            }
            
            // Calculate safe zone position (5cm above the wound marker)
            let safeZonePosition = SIMD3<Float>(woundPosition.x, woundPosition.y + 0.05, woundPosition.z)
            
            // Create safe zone line entity
            let safeZoneEntity = Entity()
            safeZoneEntity.position = safeZonePosition
            
            // Create cyan material for safe zone line
            var lineMaterial = SimpleMaterial()
            lineMaterial.color = .init(tint: UIColor.cyan)
            lineMaterial.roughness = 0.0
            lineMaterial.metallic = 1.0
            
            // Main horizontal line showing where to tie the cloth - EXTRA LARGE
            let lineMesh = MeshResource.generateBox(size: [0.35, 0.04, 0.04], cornerRadius: 0.012)
            let lineEntity = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
            
            // Create arrow markers pointing to the line - EXTRA LARGE
            let arrowMesh = MeshResource.generateBox(size: [0.08, 0.025, 0.025], cornerRadius: 0.008)
            
            // Left arrow pointing right
            let leftArrow = ModelEntity(mesh: arrowMesh, materials: [lineMaterial])
            leftArrow.position = SIMD3<Float>(-0.20, 0, 0)
            leftArrow.orientation = simd_quatf(angle: 0, axis: [0, 1, 0]) // Pointing right
            
            // Right arrow pointing left
            let rightArrow = ModelEntity(mesh: arrowMesh, materials: [lineMaterial])
            rightArrow.position = SIMD3<Float>(0.20, 0, 0)
            rightArrow.orientation = simd_quatf(angle: Float.pi, axis: [0, 1, 0]) // Pointing left
            
            // Add pulsing animation to all components
            let glowAnimation = try! AnimationResource.generate(
                with: FromToByAnimation(
                    from: Transform(scale: [1.0, 1.0, 1.0]),
                    to: Transform(scale: [1.4, 1.4, 1.4]),
                    duration: 1.0,
                    timing: .easeInOut,
                    bindTarget: .transform
                )
            )
            
            lineEntity.playAnimation(glowAnimation.repeat())
            leftArrow.playAnimation(glowAnimation.repeat())
            rightArrow.playAnimation(glowAnimation.repeat())
            
            // Add all components to safe zone entity
            safeZoneEntity.addChild(lineEntity)
            safeZoneEntity.addChild(leftArrow)
            safeZoneEntity.addChild(rightArrow)
            
            // Anchor to body skeleton
            bodyAnchor.addChild(safeZoneEntity)
            
            snapRingAnchor = bodyAnchor // Reference to body anchor
            
            // Update UI state immediately
            DispatchQueue.main.async {
                self.parent.jointWarning = nil // No joint warnings for now
                self.parent.snapRingPosition = safeZonePosition
                self.parent.snapRingValid = true
            }
            
            print("🔵 Cyan safe zone line with arrows created above X marker")
            print("📍 Safe zone positioned 5cm above wound at: \(safeZonePosition)")
            print("➡️ Arrows indicate where to tie the tourniquet cloth")
        }
        
        private func removeSnapRing() {
            if snapRing != nil || snapRingAnchor != nil {
                print("🧹 Removing snap ring")
                snapRing?.removeFromParent()
                snapRingAnchor?.removeFromParent()
                snapRing = nil
                snapRingAnchor = nil
                
                DispatchQueue.main.async {
                    self.parent.snapRingPosition = nil
                    self.parent.snapRingValid = false
                    self.parent.jointWarning = nil
                }
            }
        }
        
        private func checkForJointProximity(at position: SIMD3<Float>) -> String? {
            // Simplified joint proximity check for arm tourniquet
            // Check if position is too close to elbow or shoulder
            
            // Check if position is too close to elbow area
            if position.y < -0.1 && position.y > -0.3 {
                return "Too close to elbow—move higher"
            }
            
            // Check if position is too close to shoulder area
            if position.y > 0.3 {
                return "Too close to shoulder—move lower"
            }
            
            return nil // Safe position
        }
        
        private func isNearArmArea(position: SIMD3<Float>) -> Bool {
            // Basic validation - check if position is in reasonable arm area
            // This is a simplified check - in a real app you'd use more sophisticated body part detection
            return position.y > -0.5 && position.y < 0.5 && abs(position.x) < 0.8
        }
        
        // No body tracking needed - using simple tap-to-place system
    }
}

struct InjuryBleedingView_Previews: PreviewProvider {
    static var previews: some View {
        InjuryBleedingView(showHomeScreen: .constant(false))
    }
}
