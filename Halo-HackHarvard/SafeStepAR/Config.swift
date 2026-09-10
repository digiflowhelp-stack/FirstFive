//
//  Config.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 03/10/25.
//

import Foundation

struct Config {
    // MARK: - ElevenLabs Configuration
    // Replace with your actual ElevenLabs API key
    static let elevenLabsAPIKey = "sk_5b73d60695308d591243adf7df3775f9b51e10a956ded7d1"
    
    // Voice settings
    static let defaultVoiceStyle = "empathetic"
    static let emergencyVoiceStyle = "empathetic"
    static let trainingVoiceStyle = "calm"
    
    // Audio settings
    static let defaultPauseDuration: Double = 2.0
    static let questionPauseDuration: Double = 3.0
    static let urgentPauseDuration: Double = 1.5
}
