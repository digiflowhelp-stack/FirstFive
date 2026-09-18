//
//  EnhancedVitalsPanel.swift
//  FirstFive
//
//  Created by Harpita Pandian on 04/10/25.
//

import SwiftUI

enum VitalType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case bloodGlucose = "Blood Glucose"
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .bloodGlucose: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .bloodGlucose: return .red
        }
    }
}

struct VitalData {
    let value: String
    let unit: String
    let status: VitalStatus
    let range: String
    let values: [Int] // For cycling through values
}

enum VitalStatus {
    case safe
    case dangerous
    
    var color: Color {
        switch self {
        case .safe: return .green
        case .dangerous: return .red
        }
    }
    
    var text: String {
        switch self {
        case .safe: return "safe range"
        case .dangerous: return "dangerous range"
        }
    }
}

struct EnhancedVitalsPanel: View {
    let isAllergicReaction: Bool
    let isCardiacArrest: Bool
    @State private var currentVitalIndex = 0
    @State private var heartScale: CGFloat = 1.0
    @State private var currentHeartRate: Int = 85
    @State private var currentGlucose: Int = 400
    @State private var dataSyncAnimation: Bool = false
    @State private var panelPulseAnimation: Bool = false
    
    init(isAllergicReaction: Bool = false, isCardiacArrest: Bool = false) {
        self.isAllergicReaction = isAllergicReaction
        self.isCardiacArrest = isCardiacArrest
    }
    
    private let heartRateValues = [85, 89, 88, 87]
    private let allergicReactionHeartRateValues = [120, 118, 120, 118] // High heart rate for allergic reactions
    private let glucoseValues = [400, 470, 500] // Dangerous values as requested
    
    private var currentVital: VitalType {
        VitalType.allCases[currentVitalIndex]
    }
    
    private var vitalData: VitalData {
        switch currentVital {
        case .heartRate:
            if isCardiacArrest {
                return VitalData(
                    value: "-",
                    unit: "BPM",
                    status: .safe, // Won't be shown anyway
                    range: "",
                    values: []
                )
            } else {
                let heartRateStatus: VitalStatus = isAllergicReaction ? .dangerous : .safe
                let heartRateRange = isAllergicReaction ? "dangerously high" : "safe range"
                let heartRateValuesToUse = isAllergicReaction ? allergicReactionHeartRateValues : heartRateValues
                
                return VitalData(
                    value: "\(currentHeartRate)",
                    unit: "BPM",
                    status: heartRateStatus,
                    range: heartRateRange,
                    values: heartRateValuesToUse
                )
            }
        case .bloodGlucose:
            return VitalData(
                value: "\(currentGlucose)",
                unit: "mg/dL",
                status: .dangerous,
                range: "dangerous range",
                values: glucoseValues
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Data Synced Indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
                    .scaleEffect(dataSyncAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: dataSyncAnimation)
                
                Text("Data Synced")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // Navigation arrows
                HStack(spacing: 8) {
                    Button(action: previousVital) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: nextVital) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            VStack(spacing: 12) {
                // Vital icon with animation
                Image(systemName: currentVital.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(isCardiacArrest && currentVital == .heartRate ? .gray : currentVital.color)
                    .scaleEffect(currentVital == .heartRate && !isCardiacArrest ? heartScale : 1.0)
                    .onAppear {
                        if currentVital == .heartRate {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                heartScale = 1.3
                            }
                        }
                    }
                
                // Vital value - dynamically changing
                Text("\(vitalData.value) \(vitalData.unit)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // Time range for glucose
                if currentVital == .bloodGlucose {
                    Text("Past 3 hours")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.8))
                        )
                }
            }
            .padding(20)
            
            // Status range label - hidden for cardiac arrest
            if !isCardiacArrest {
                Text(vitalData.status.text)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(vitalData.status.color.opacity(0.8))
                    )
            }
        }
        .scaleEffect(panelPulseAnimation ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: panelPulseAnimation)
        .onAppear {
            startDataCycling()
            dataSyncAnimation = true
            panelPulseAnimation = true
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        previousVital()
                    } else if value.translation.width < -50 {
                        nextVital()
                    }
                }
        )
    }
    
    private func nextVital() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentVitalIndex = (currentVitalIndex + 1) % VitalType.allCases.count
        }
    }
    
    private func previousVital() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentVitalIndex = currentVitalIndex == 0 ? VitalType.allCases.count - 1 : currentVitalIndex - 1
        }
    }
    
    private func startDataCycling() {
        var heartIndex = 0
        var glucoseIndex = 0
        
        // Set initial heart rate based on scenario
        let heartRateValuesToUse = isAllergicReaction ? allergicReactionHeartRateValues : heartRateValues
        currentHeartRate = heartRateValuesToUse[0]
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Cycle heart rate values based on scenario
                currentHeartRate = heartRateValuesToUse[heartIndex]
                heartIndex = (heartIndex + 1) % heartRateValuesToUse.count
                
                // Cycle glucose values
                currentGlucose = glucoseValues[glucoseIndex]
                glucoseIndex = (glucoseIndex + 1) % glucoseValues.count
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        EnhancedVitalsPanel(isAllergicReaction: false, isCardiacArrest: false)
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
    }
}
