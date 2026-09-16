//
//  SeizureView.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 30/09/25.
//

import SwiftUI

struct SeizureView: View {
    @Binding var showHomeScreen: Bool
    @EnvironmentObject var voiceManager: VoiceGuidanceManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
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
            
            VStack(spacing: 30) {
                // Back Button
                HStack {
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
                .padding(.top, 20)
                
                Spacer()
                
                // Seizure Icon and Title
                VStack(spacing: 20) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text("Seizure Response")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Coming Soon")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Placeholder content
                VStack(spacing: 16) {
                    Text("This emergency scenario will include:")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                            Text("Safe positioning guidance")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                            Text("Seizure timing and monitoring")
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                            Text("Recovery position assistance")
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .firstFiveVoiceIndicator(voiceManager)
        .preferredColorScheme(.dark)
    }
}

struct SeizureView_Previews: PreviewProvider {
    static var previews: some View {
        SeizureView(showHomeScreen: .constant(false))
    }
}
