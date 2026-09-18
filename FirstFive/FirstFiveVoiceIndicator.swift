//
//  FirstFiveVoiceIndicator.swift
//  FirstFive
//
//  Created by Harpita Pandian on 04/10/25.
//

import SwiftUI

struct FirstFiveVoiceIndicator: View {
    @ObservedObject var voiceManager: VoiceGuidanceManager
    @State private var waveAnimations: [Bool] = Array(repeating: false, count: 5)
    
    var body: some View {
        VStack(spacing: 8) {
            if voiceManager.isCurrentlySpeaking {
                // Audio wave bars - larger and centered
                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                            .frame(width: 5, height: waveAnimations[index] ? CGFloat.random(in: 20...40) : 10)
                            .animation(
                                .easeInOut(duration: Double.random(in: 0.3...0.8))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: waveAnimations[index]
                            )
                    }
                }
                
                // Just "FirstFive" text
                Text("FirstFive")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .background(
            Circle()
                .fill(Color.white.opacity(0.15))
                .blur(radius: 1)
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.0, green: 1.0, blue: 0.0).opacity(0.9), lineWidth: 3)
                        .blur(radius: 1)
                        .scaleEffect(voiceManager.isCurrentlySpeaking ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: voiceManager.isCurrentlySpeaking)
                )
                .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.0).opacity(0.6), radius: 12, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .opacity(voiceManager.isCurrentlySpeaking ? 1.0 : 0.0)
        .scaleEffect(voiceManager.isCurrentlySpeaking ? 1.0 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: voiceManager.isCurrentlySpeaking)
        .onAppear {
            // Start animations immediately if already speaking
            if voiceManager.isCurrentlySpeaking {
                startWaveAnimations()
            }
        }
        .onChange(of: voiceManager.isCurrentlySpeaking) { _, isSpeaking in
            if isSpeaking {
                // Force restart animations
                stopWaveAnimations()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startWaveAnimations()
                }
            } else {
                stopWaveAnimations()
            }
        }
    }
    
    private func startWaveAnimations() {
        // Reset all animations first
        for index in 0..<waveAnimations.count {
            waveAnimations[index] = false
        }
        
        // Start animations with staggered delays
        for index in 0..<waveAnimations.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation {
                    waveAnimations[index] = true
                }
            }
        }
    }
    
    private func stopWaveAnimations() {
        withAnimation(.easeOut(duration: 0.2)) {
            for index in 0..<waveAnimations.count {
                waveAnimations[index] = false
            }
        }
    }
}

// MARK: - Overlay Extension for Easy Integration
extension View {
    func firstFiveVoiceIndicator(_ voiceManager: VoiceGuidanceManager) -> some View {
        self.overlay(
            FirstFiveVoiceIndicator(voiceManager: voiceManager)
                .position(x: UIScreen.main.bounds.width / 2, y: 80),
            alignment: .top
        )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var voiceManager = VoiceGuidanceManager(apiKey: "test")
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack {
                    Text("Emergency Screen")
                        .font(.title)
                    
                    Button("Toggle Voice") {
                        voiceManager.isCurrentlySpeaking.toggle()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .firstFiveVoiceIndicator(voiceManager)
        }
    }
    
    return PreviewWrapper()
}
