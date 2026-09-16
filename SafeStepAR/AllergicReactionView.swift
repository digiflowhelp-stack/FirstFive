//
//  AllergicReactionView.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 30/09/25.
//

import SwiftUI

struct AllergicReactionView: View {
    @Binding var showHomeScreen: Bool
    @EnvironmentObject var voiceManager: VoiceGuidanceManager
    @State private var instructionPressed = false
    @State private var heartRatePressed = false
    @State private var isPersonLyingDown = false
    
    // Sequential panel states
    @State private var showTimerPanel = false
    @State private var showCountdown = false
    @State private var countdownValue = 3
    @State private var showMonitorPanel = false
    
    // Panel pulsing animations
    @State private var instructionPanelScale: CGFloat = 1.0
    @State private var timerPanelScale: CGFloat = 1.0
    @State private var monitorPanelScale: CGFloat = 1.0
    
    // New instruction panel states
    @State private var instructionFlashColor = Color.red
    @State private var instructionText = "Help person lie down flat"
    @State private var isInSafePosition = false
    @State private var showChairMessage = false
    @State private var showDownwardArrows = false
    @State private var elementsLoaded = true
    
    var body: some View {
        ZStack {
            // ARView Container
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
            
            // No loading delay - elements appear immediately
            
            // Back Button (top-left) - only show after elements load
            if elementsLoaded {
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
            }
            
            // Enhanced Vitals Panel (top-left) - only show after elements load
            if elementsLoaded {
                EnhancedVitalsPanel(isAllergicReaction: true)
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
                .scaleEffect(heartRatePressed ? 1.02 : 1.0)
                .rotation3DEffect(
                    Angle.degrees(15),
                    axis: (x: 1.0, y: 0.3, z: 0.0),
                    perspective: 0.6
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        heartRatePressed.toggle()
                    }
                }
                .position(x: UIScreen.main.bounds.width * 0.3, y: 150)
            }
            
            // Step 1: Dynamic Instruction Panel (top-right) - only show after elements load
            if elementsLoaded {
                InstructionPanel(
                    text: instructionText,
                    isInSafePosition: isInSafePosition
                )
                .frame(width: 280, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isInSafePosition ? Color.green.opacity(0.8) : instructionFlashColor.opacity(0.7))
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                )
                .scaleEffect(instructionPressed ? 1.02 : instructionPanelScale)
                .onAppear {
                    startInstructionAnimations()
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        instructionPanelScale = 1.03
                    }
                }
                .rotation3DEffect(
                    Angle.degrees(-15),
                    axis: (x: 1.0, y: 0.2, z: 0.0),
                    perspective: 0.6
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        instructionPressed.toggle()
                    }
                }
                .position(x: UIScreen.main.bounds.width * 0.7, y: 200)
            }
            
            // Step 2: Timer Panel (appears after 15 seconds) - only show after elements load
            if elementsLoaded && showTimerPanel {
                TimerPanel(showCountdown: false, countdownValue: 0)
                    .frame(width: 280, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(timerPanelScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                            timerPanelScale = 1.025
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
            // Step 3: Monitor Panel (appears after countdown) - only show after elements load
            if elementsLoaded && showMonitorPanel {
                MonitorPanel(showCountdown: showCountdown, countdownValue: countdownValue)
                    .frame(width: 280, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.7))
                            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(monitorPanelScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            monitorPanelScale = 1.02
                        }
                    }
                    .rotation3DEffect(
                        Angle.degrees(-8),
                        axis: (x: 1.0, y: 0.0, z: 0.0),
                        perspective: 0.6
                    )
                    .position(x: UIScreen.main.bounds.width * 0.7, y: 500)
                    .transition(.scale)
            }
            
            // Downward Arrows Animation (appears 3 seconds after panel 2) - only show after elements load
            if elementsLoaded && showDownwardArrows {
                VStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.orange)
                            .scaleEffect(showDownwardArrows ? 1.2 : 1.0)
                            .offset(y: showDownwardArrows ? 100 : -50)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                                value: showDownwardArrows
                            )
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: showDownwardArrows
                            )
                    }
                }
                .position(x: UIScreen.main.bounds.width * 0.6, y: UIScreen.main.bounds.height * 0.65)
                .transition(.opacity)
            }
            
            // Chair Support Message (appears for 10 seconds) - only show after elements load
            if elementsLoaded && showChairMessage {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "chair.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.cyan)
                        
                        Text("Use a chair for support")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.cyan.opacity(0.3))
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
                )
                .position(x: UIScreen.main.bounds.width * 0.7, y: 280)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .firstFiveVoiceIndicator(voiceManager)
        .preferredColorScheme(.dark)
        .onAppear {
            startSequentialWorkflow()
            
            // Show chair message after 20 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showChairMessage = true
                }
                
                // Hide chair message after 8 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showChairMessage = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .safePositionChanged)) { notification in
            if let inSafePosition = notification.object as? Bool {
                // Handle safe position change if needed
            }
        }
    }
    
    // Sequential workflow timing
    private func startSequentialWorkflow() {
        // Step 1: Initial panel is already visible
        
        // Step 2: Show timer panel only after first panel turns green (38 seconds + 2 seconds + 8 seconds extra)
        DispatchQueue.main.asyncAfter(deadline: .now() + 48) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showTimerPanel = true
            }
            
            // Show downward arrows 3 seconds after timer panel appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showDownwardArrows = true
                }
                
                // Hide arrows after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showDownwardArrows = false
                    }
                }
            }
            
            // Show monitor panel after 18 seconds and start countdown (6 seconds earlier)
            DispatchQueue.main.asyncAfter(deadline: .now() + 18) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showMonitorPanel = true
                }
                
                // Notify that panel 3 appeared to change EpiPen markers to red
                NotificationCenter.default.post(name: .panel3Appeared, object: nil)
                
                // Start countdown after monitor panel appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    startCountdown()
                }
            }
        }
    }
    
    // Instruction panel animations
    private func startInstructionAnimations() {
        // Flash between red and orange colors
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isInSafePosition {
                withAnimation(.easeInOut(duration: 0.5)) {
                    instructionFlashColor = instructionFlashColor == .red ? .orange : .red
                }
            } else {
                timer.invalidate()
            }
        }
        
        // Show "Help person lie down" for first 17 seconds, then "Raise their legs above line"
        Timer.scheduledTimer(withTimeInterval: 17.0, repeats: false) { _ in
            if !isInSafePosition {
                withAnimation(.easeInOut(duration: 0.3)) {
                    instructionText = "Raise their legs above line"
                }
            }
        }
        
        // Change to safe position after 38 seconds (delayed by 18 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 38) {
            withAnimation(.easeInOut(duration: 0.8)) {
                isInSafePosition = true
                instructionText = "Person is now in Safe Position"
            }
            
            // Notify BodySkeleton to change baseline to green
            NotificationCenter.default.post(name: .safePositionChanged, object: true)
        }
    }
    
    private func startCountdown() {
        showCountdown = true
        countdownValue = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                countdownValue -= 1
            }
            
            if countdownValue <= 0 {
                timer.invalidate()
            }
        }
    }
}

struct AllergicReactionView_Previews: PreviewProvider {
    static var previews: some View {
        AllergicReactionView(showHomeScreen: .constant(false))
    }
}
