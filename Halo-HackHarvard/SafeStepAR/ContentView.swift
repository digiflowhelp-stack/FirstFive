//
//  ContentView.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 28/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedScenario: EmergencyScenario? = nil
    @State private var showHomeScreen = true
    @StateObject private var voiceManager = VoiceGuidanceManager(apiKey: Config.elevenLabsAPIKey)
    
    var body: some View {
        Group {
            if showHomeScreen {
                HomeScreenView(selectedScenario: $selectedScenario)
                    .onChange(of: selectedScenario) { _, scenario in
                        if scenario != nil {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showHomeScreen = false
                            }
                        }
                    }
            } else {
                switch selectedScenario {
                case .allergicReaction:
                    AllergicReactionView(showHomeScreen: $showHomeScreen)
                        .environmentObject(voiceManager)
                        .onAppear {
                            voiceManager.startAutoStartCountdown(for: .allergicReaction)
                        }
                        .onChange(of: showHomeScreen) { _, show in
                            if show {
                                selectedScenario = nil
                                voiceManager.stopGuidance()
                            }
                        }
                case .stroke:
                    StrokeView(showHomeScreen: $showHomeScreen)
                        .environmentObject(voiceManager)
                        .onAppear {
                            voiceManager.startAutoStartCountdown(for: .stroke)
                        }
                        .onChange(of: showHomeScreen) { _, show in
                            if show {
                                selectedScenario = nil
                                voiceManager.stopGuidance()
                            }
                        }
                case .injuryBleeding:
                    InjuryBleedingView(showHomeScreen: $showHomeScreen)
                        .environmentObject(voiceManager)
                        .onAppear {
                            voiceManager.startAutoStartCountdown(for: .injuryBleeding)
                        }
                        .onChange(of: showHomeScreen) { _, show in
                            if show {
                                selectedScenario = nil
                                voiceManager.stopGuidance()
                            }
                        }
                case .cardiacArrest:
                    CardiacArrestView(showHomeScreen: $showHomeScreen)
                        .environmentObject(voiceManager)
                        .onAppear {
                            voiceManager.startAutoStartCountdown(for: .cardiacArrest)
                        }
                        .onChange(of: showHomeScreen) { _, show in
                            if show {
                                selectedScenario = nil
                                voiceManager.stopGuidance()
                            }
                        }
                case .none:
                    HomeScreenView(selectedScenario: $selectedScenario)
                }
            }
        }
        .preferredColorScheme(showHomeScreen ? .light : .dark)
    }
}

struct InstructionPanel: View {
    let text: String
    let isInSafePosition: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(text)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if isInSafePosition {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct HeartRatePanel: View {
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

struct VisionOSWindow: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header with emergency icon
            HStack {
                Image(systemName: "cross.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 24, weight: .bold))
                
                Text("Emergency Status")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Status information
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.stand")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                    
                    Text("Help person lie down")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "syringe")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                    
                    Text("EpiPen sites marked")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Spacer()
        }
        .padding(20)
    }
}

struct VitalsGlassCard: View {
    var body: some View {
        VStack(spacing: 20) {
            // --- HEART RATE ---
            HStack(spacing: 15) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink) // nice pink heart
                    .font(.system(size: 40, weight: .bold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Heart Rate")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Text("77 BPM")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.22))

            // --- OXYGEN ---
            HStack(spacing: 15) {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 36, weight: .bold))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Oxygen")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                    Text("80 %")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                Spacer()
            }
        }
        .padding()
        .environment(\.font, .system(.body, design: .rounded))
    }
}

struct TimerPanel: View {
    let showCountdown: Bool
    let countdownValue: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find the X marker on the thigh")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Inject the epipen orange side facing down")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(16)
    }
}

struct MonitorPanel: View {
    let showCountdown: Bool
    let countdownValue: Int
    
    var body: some View {
        VStack(spacing: showCountdown ? 8 : 12) {
            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: showCountdown ? 22 : 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "phone.fill")
                        .font(.system(size: showCountdown ? 16 : 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Hold for 3 seconds")
                        .font(.system(size: showCountdown ? 15 : 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Monitor breathing and call 911")
                        .font(.system(size: showCountdown ? 13 : 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if showCountdown && countdownValue > 0 {
                Text("\(countdownValue)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(countdownValue > 0 ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: countdownValue)
            }
        }
        .padding(showCountdown ? 12 : 16)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
