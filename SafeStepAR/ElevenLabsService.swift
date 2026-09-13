//
//  ElevenLabsService.swift
//  SafeStepAR
//
//  Created by Harpita Pandian on 03/10/25.
//

import Foundation
import AVFoundation
import Combine

class ElevenLabsService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    // Popular female voices - you can change these IDs
    private let voiceIDs = [
        "empathetic": "EXAVITQu4vr4xnSDxMaL", // Bella - warm and empathetic
        "calm": "21m00Tcm4TlvDq8ikWAM", // Rachel - calm and soothing
        "professional": "AZnzlk1XvdvUeBnXmlld" // Domi - professional but warm
    ]
    
    private var audioPlayer: AVAudioPlayer?
    private var audioDelegate: AudioPlayerDelegate?
    private var currentVoiceID: String
    
    // Callbacks for audio state changes
    var onAudioStart: (() -> Void)?
    var onAudioStop: (() -> Void)?
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.currentVoiceID = voiceIDs["empathetic"] ?? "EXAVITQu4vr4xnSDxMaL"
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Voice Selection
    func setVoiceStyle(_ style: String) {
        if let voiceID = voiceIDs[style] {
            currentVoiceID = voiceID
        }
    }
    
    // MARK: - Text to Speech
    func synthesizeAndPlay(text: String, emotion: VoiceEmotion = .calm, completion: @escaping (Bool) -> Void) {
        let settings = getVoiceSettings(for: emotion)
        
        guard let url = URL(string: "\(baseURL)/text-to-speech/\(currentVoiceID)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": settings
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Failed to serialize request body: \(error)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("API request failed: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Check for API errors
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                print("API returned status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Play the audio
            DispatchQueue.main.async {
                self.playAudioData(data, completion: completion)
            }
        }.resume()
    }
    
    private func playAudioData(_ data: Data, completion: @escaping (Bool) -> Void) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioDelegate = AudioPlayerDelegate(
                completion: completion,
                onStart: onAudioStart,
                onStop: onAudioStop
            )
            audioPlayer?.delegate = audioDelegate
            
            // Notify that audio is starting
            onAudioStart?()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error)")
            completion(false)
        }
    }
    
    private func getVoiceSettings(for emotion: VoiceEmotion) -> [String: Any] {
        switch emotion {
        case .calm:
            return [
                "stability": 0.75,
                "similarity_boost": 0.8,
                "style": 0.2,
                "use_speaker_boost": true
            ]
        case .reassuring:
            return [
                "stability": 0.8,
                "similarity_boost": 0.85,
                "style": 0.3,
                "use_speaker_boost": true
            ]
        case .urgent:
            return [
                "stability": 0.6,
                "similarity_boost": 0.7,
                "style": 0.6,
                "use_speaker_boost": true
            ]
        case .encouraging:
            return [
                "stability": 0.7,
                "similarity_boost": 0.8,
                "style": 0.4,
                "use_speaker_boost": true
            ]
        case .instructional:
            return [
                "stability": 0.8,
                "similarity_boost": 0.75,
                "style": 0.1,
                "use_speaker_boost": true
            ]
        }
    }
    
    // MARK: - Script Playback
    func playVoiceScript(_ script: VoiceScript, completion: @escaping () -> Void) {
        playSegments(script.segments, index: 0, completion: completion)
    }
    
    private func playSegments(_ segments: [VoiceSegment], index: Int, completion: @escaping () -> Void) {
        guard index < segments.count else {
            completion()
            return
        }
        
        let segment = segments[index]
        
        synthesizeAndPlay(text: segment.text, emotion: segment.emotion) { [weak self] success in
            if success {
                // Wait for the specified pause duration
                DispatchQueue.main.asyncAfter(deadline: .now() + segment.pauseDuration) {
                    self?.playSegments(segments, index: index + 1, completion: completion)
                }
            } else {
                // If synthesis fails, continue to next segment after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.playSegments(segments, index: index + 1, completion: completion)
                }
            }
        }
    }
    
    // MARK: - Control Methods
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        onAudioStop?()
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
    }
    
    func resumePlayback() {
        audioPlayer?.play()
    }
}

// MARK: - Audio Player Delegate
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let completion: (Bool) -> Void
    private let onStart: (() -> Void)?
    private let onStop: (() -> Void)?
    
    init(completion: @escaping (Bool) -> Void, onStart: (() -> Void)? = nil, onStop: (() -> Void)? = nil) {
        self.completion = completion
        self.onStart = onStart
        self.onStop = onStop
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onStop?()
        completion(flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        onStop?()
        completion(false)
    }
}
