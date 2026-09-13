//
//  HomeScreenView.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 30/09/25.
//

import SwiftUI

struct HomeScreenView: View {
    @Binding var selectedScenario: EmergencyScenario?
    
    // Animation states
    @State private var heartScale: CGFloat = 1.0
    @State private var heartGlow: CGFloat = 0.0
    @State private var titleOffset: CGFloat = 0
    @State private var showCards = false
    
    // Mode toggle
    @State private var isTrainingMode = false
    
    // Training progress (mock data)
    @State private var completedProtocols: Set<EmergencyScenario> = [.injuryBleeding]
    
    // Neon green color
    private let neonGreen = Color(red: 0.0, green: 1.0, blue: 0.0)
    
    var body: some View {
        ZStack {
            // Pure white background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top bar with user profile
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Halo User")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                            
                            Text("Student Profile")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 10)
                
                // Mode Toggle
                HStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        // Emergency Mode Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isTrainingMode = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("EMERGENCY")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(0.5)
                            }
                            .foregroundColor(isTrainingMode ? .black.opacity(0.6) : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(isTrainingMode ? Color.clear : Color.red)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.red, lineWidth: 1.5)
                                    )
                            )
                        }
                        
                        // Training Mode Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isTrainingMode = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("TRAINING")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .tracking(0.5)
                            }
                            .foregroundColor(isTrainingMode ? .white : .black.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(isTrainingMode ? neonGreen : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(neonGreen, lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Training Progress Bar (only show in training mode)
                if isTrainingMode {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Training Progress")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("\(completedProtocols.count)/\(EmergencyScenario.allCases.count) Protocols Completed")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Progress percentage
                            Text("\(Int(Double(completedProtocols.count) / Double(EmergencyScenario.allCases.count) * 100))%")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(neonGreen)
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.black.opacity(0.1))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(neonGreen)
                                    .frame(width: geometry.size.width * (Double(completedProtocols.count) / Double(EmergencyScenario.allCases.count)), height: 8)
                                    .animation(.easeInOut(duration: 0.5), value: completedProtocols.count)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Header Section
                VStack(spacing: 20) {
                    // App Logo
                    Image("halo-app 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .scaleEffect(heartScale)
                    .padding(.top, 100)
                    
                    // App Title
                    Text("Halo")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .offset(x: titleOffset)
                    
                    // Tagline
                    VStack(spacing: 8) {
                        Text("Spatial AR Overlays with AI Agent Voice Guidance")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Text("to save a life")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 60)
                
                // Emergency Tiles
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(EmergencyScenario.allCases, id: \.self) { scenario in
                            HaloEmergencyTile(
                                scenario: scenario,
                                neonGreen: neonGreen,
                                isTrainingMode: isTrainingMode,
                                isCompleted: completedProtocols.contains(scenario)
                            ) {
                                selectedScenario = scenario
                            }
                            .opacity(showCards ? 1.0 : 0.0)
                            .offset(y: showCards ? 0 : 50)
                            .animation(.easeOut(duration: 0.6).delay(Double(EmergencyScenario.allCases.firstIndex(of: scenario) ?? 0) * 0.1), value: showCards)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Heart pulsing animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            heartScale = 1.15
        }
        
        // Title floating animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            titleOffset = 5
        }
        
        // Cards appear animation
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            showCards = true
        }
    }
}

struct HaloEmergencyTile: View {
    let scenario: EmergencyScenario
    let neonGreen: Color
    let isTrainingMode: Bool
    let isCompleted: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var hoverEffect = false
    
    // Light green accent color
    private let lightGreen = Color(red: 0.9, green: 1.0, blue: 0.9)
    private let darkCard = Color(red: 0.1, green: 0.1, blue: 0.1)
    private let completedGreen = Color(red: 0.85, green: 0.95, blue: 0.85)
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
            }
        }) {
            HStack(spacing: 24) {
                // Left side - Icon
                ZStack {
                    Circle()
                        .fill(isTrainingMode && isCompleted ? Color.green.opacity(0.2) : neonGreen.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(isTrainingMode && isCompleted ? Color.green : neonGreen.opacity(0.4), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    
                    if isTrainingMode && isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: scenario.icon)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(darkCard)
                    }
                }
                
                // Right side - Content
                VStack(alignment: .leading, spacing: 12) {
                    // Title and urgency
                    VStack(alignment: .leading, spacing: 6) {
                        Text(scenario.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(darkCard)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(scenario.urgencyColor)
                                .frame(width: 8, height: 8)
                            
                            Text(scenario.urgencyLevel)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(scenario.urgencyColor)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }
                    
                    // Description
                    Text(scenario.description)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(darkCard.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    // Key steps preview
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Steps:")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(darkCard.opacity(0.6))
                        
                        ForEach(scenario.keySteps.prefix(2), id: \.self) { step in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(neonGreen)
                                    .frame(width: 4, height: 4)
                                
                                Text(step)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(darkCard.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        
                        if scenario.keySteps.count > 2 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(neonGreen.opacity(0.5))
                                    .frame(width: 4, height: 4)
                                
                                Text("+ \(scenario.keySteps.count - 2) more steps")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.red)
                                    .italic()
                            }
                        }
                    }
                    
                    // Training mode specific content
                    if isTrainingMode {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Training Status:")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(darkCard.opacity(0.6))
                                
                                Spacer()
                                
                                if isCompleted {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.green)
                                        
                                        Text("COMPLETED")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.green)
                                            .tracking(0.5)
                                    }
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.orange)
                                        
                                        Text("PENDING")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.orange)
                                            .tracking(0.5)
                                    }
                                }
                            }
                            
                            // Training progress indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(isCompleted ? .green : neonGreen)
                                    .frame(width: 6, height: 6)
                                
                                Text(isCompleted ? "Protocol mastered - Review available" : "Start training simulation")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(darkCard.opacity(0.7))
                                    .italic()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action button
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text(isTrainingMode ? (isCompleted ? "REVIEW TRAINING" : "BEGIN TRAINING") : "BEGIN PROTOCOL")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(1.0)
                            
                            Image(systemName: isTrainingMode ? "graduationcap.fill" : "arrow.right.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                if !isTrainingMode {
                                    // Pulsing red glow background for emergency mode
                                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                                        .fill(Color.red.opacity(0.3))
                                        .blur(radius: 8)
                                        .scaleEffect(hoverEffect ? 1.1 : 1.0)
                                }
                                
                                // Main button
                                RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(isTrainingMode ? (isCompleted ? neonGreen : Color.blue) : Color.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                                            .stroke(isTrainingMode ? (isCompleted ? neonGreen : Color.blue) : Color.red.opacity(0.6), lineWidth: 2)
                                    )
                            }
                        )
                        .shadow(color: isTrainingMode ? (isCompleted ? neonGreen.opacity(0.4) : Color.blue.opacity(0.4)) : Color.red.opacity(0.4), radius: 12, x: 0, y: 4)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                }
                
                Spacer()
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(isTrainingMode && isCompleted ? completedGreen : lightGreen)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(isTrainingMode && isCompleted ? Color.green.opacity(0.4) : neonGreen.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: isTrainingMode && isCompleted ? Color.green.opacity(0.15) : neonGreen.opacity(0.15), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(isPressed ? 0.98 : (hoverEffect ? 1.005 : 1.0))
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: hoverEffect)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                hoverEffect = true
            }
        }
    }
}

enum EmergencyScenario: CaseIterable {
    case allergicReaction
    case stroke
    case injuryBleeding
    case cardiacArrest
    
    var title: String {
        switch self {
        case .allergicReaction:
            return "Allergic Reaction"
        case .stroke:
            return "Stroke"
        case .injuryBleeding:
            return "Injury & Bleeding"
        case .cardiacArrest:
            return "Cardiac Arrest"
        }
    }
    
    var description: String {
        switch self {
        case .allergicReaction:
            return "Life-threatening allergic response requiring immediate EpiPen administration and emergency care."
        case .stroke:
            return "Time-critical brain emergency using FAST assessment protocol for rapid identification."
        case .injuryBleeding:
            return "Trauma response with wound assessment, bleeding control, and tourniquet application."
        case .cardiacArrest:
            return "Critical cardiac emergency requiring immediate CPR and life support measures."
        }
    }
    
    var urgencyLevel: String {
        switch self {
        case .allergicReaction:
            return "Critical"
        case .stroke:
            return "Critical"
        case .injuryBleeding:
            return "High"
        case .cardiacArrest:
            return "Critical"
        }
    }
    
    var urgencyColor: Color {
        switch self {
        case .allergicReaction, .stroke, .cardiacArrest:
            return .red
        case .injuryBleeding:
            return .orange
        }
    }
    
    var keySteps: [String] {
        switch self {
        case .allergicReaction:
            return [
                "Position person lying down",
                "Locate EpiPen injection sites",
                "Administer EpiPen to thigh",
                "Monitor breathing & vitals",
                "Call emergency services"
            ]
        case .stroke:
            return [
                "Face: Check for facial drooping",
                "Arms: Test arm weakness",
                "Speech: Assess speech clarity",
                "Time: Note symptom onset",
                "Call 911 immediately"
            ]
        case .injuryBleeding:
            return [
                "Assess wound severity",
                "Apply direct pressure",
                "Elevate injured area",
                "Apply tourniquet if needed",
                "Monitor for shock signs"
            ]
        case .cardiacArrest:
            return [
                "Check responsiveness",
                "Call 911 & get AED",
                "Begin chest compressions",
                "Provide rescue breaths",
                "Continue CPR cycles"
            ]
        }
    }
    
    var icon: String {
        switch self {
        case .allergicReaction:
            return "cross.circle"
        case .stroke:
            return "brain.head.profile"
        case .injuryBleeding:
            return "drop.circle"
        case .cardiacArrest:
            return "heart.circle"
        }
    }
}

struct HomeScreenView_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreenView(selectedScenario: .constant(nil))
    }
}
