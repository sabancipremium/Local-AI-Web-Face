// TTSManager.swift
// Local-AI-Web-Face
//
// Text-to-Speech manager service

import Foundation
import AVFoundation
import Combine

@MainActor
class TTSManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    // MARK: - Published Properties
    
    @Published var isSpeaking: Bool = false
    @Published var availableVoices: [AVSpeechSynthesisVoice] = []
    @Published var selectedVoiceIdentifier: String? = nil
    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    @Published var isTTSEnabled: Bool = true
    @Published var isPaused: Bool = false
    
    // MARK: - Private Properties
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private struct Keys {
        static let selectedVoice = "selectedTTSVoiceIdentifier"
        static let speechRate = "speechRateTTS"
        static let ttsEnabled = "isTTSEnabled"
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechSynthesizer.delegate = self
        fetchAvailableVoices()
        loadSettings()
    }
    
    // MARK: - Voice Management
    
    func fetchAvailableVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("en") } // Focus on English voices for Phase 1
            .sorted { $0.name < $1.name }
        
        // Validate selected voice
        if let selectedID = selectedVoiceIdentifier {
            if !availableVoices.contains(where: { $0.identifier == selectedID }) {
                selectedVoiceIdentifier = nil
                saveSettings()
            }
        }
        
        // Set default voice if none selected
        if selectedVoiceIdentifier == nil, let defaultVoice = availableVoices.first {
            selectedVoiceIdentifier = defaultVoice.identifier
            saveSettings()
        }
    }
    
    func selectVoice(identifier: String?) {
        selectedVoiceIdentifier = identifier
        saveSettings()
    }
    
    var selectedVoice: AVSpeechSynthesisVoice? {
        guard let identifier = selectedVoiceIdentifier else { return nil }
        return availableVoices.first { $0.identifier == identifier }
    }
    
    // MARK: - Speech Control
    
    func speak(text: String) {
        guard isTTSEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Stop current speech if speaking
        if isSpeaking {
            stopSpeaking()
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice
        if let voice = selectedVoice {
            utterance.voice = voice
        }
        
        // Set speech rate (clamp to valid range)
        utterance.rate = max(AVSpeechUtteranceMinimumSpeechRate, 
                           min(AVSpeechUtteranceMaximumSpeechRate, speechRate))
        
        // Set pitch and volume
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    func pauseSpeaking() {
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func continueSpeaking() {
        speechSynthesizer.continueSpeaking()
    }
    
    // MARK: - Settings Management
    
    func setSpeechRate(rate: Float) {
        speechRate = max(AVSpeechUtteranceMinimumSpeechRate, 
                        min(AVSpeechUtteranceMaximumSpeechRate, rate))
        saveSettings()
    }
    
    func toggleTTSEnabled(enabled: Bool) {
        isTTSEnabled = enabled
        if !enabled && isSpeaking {
            stopSpeaking()
        }
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let voiceID = selectedVoiceIdentifier {
            userDefaults.set(voiceID, forKey: Keys.selectedVoice)
        } else {
            userDefaults.removeObject(forKey: Keys.selectedVoice)
        }
        
        userDefaults.set(speechRate, forKey: Keys.speechRate)
        userDefaults.set(isTTSEnabled, forKey: Keys.ttsEnabled)
    }
    
    private func loadSettings() {
        selectedVoiceIdentifier = userDefaults.string(forKey: Keys.selectedVoice)
        
        let savedRate = userDefaults.object(forKey: Keys.speechRate) as? Float
        speechRate = savedRate ?? AVSpeechUtteranceDefaultSpeechRate
        
        let savedEnabled = userDefaults.object(forKey: Keys.ttsEnabled) as? Bool
        isTTSEnabled = savedEnabled ?? true
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPaused = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            isPaused = false
        }
    }
    
    // MARK: - Utility Methods
    
    var canSpeak: Bool {
        return isTTSEnabled && !availableVoices.isEmpty
    }
    
    var speechRatePercentage: Int {
        let range = AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate
        let normalized = (speechRate - AVSpeechUtteranceMinimumSpeechRate) / range
        return Int(normalized * 100)
    }
    
    func setSpeechRateFromPercentage(_ percentage: Int) {
        let range = AVSpeechUtteranceMaximumSpeechRate - AVSpeechUtteranceMinimumSpeechRate
        let normalized = Float(percentage) / 100.0
        let rate = AVSpeechUtteranceMinimumSpeechRate + (normalized * range)
        setSpeechRate(rate: rate)
    }
    
    // MARK: - Debug and Testing
    
    func testSpeak() {
        speak(text: "Hello! This is a test of the text-to-speech system. I can speak AI responses to help you listen to conversations.")
    }
    
    func getVoiceInfo() -> String {
        guard let voice = selectedVoice else { return "No voice selected" }
        return "\(voice.name) (\(voice.language))"
    }
}

// MARK: - Extensions

extension TTSManager {
    
    /// Returns a user-friendly status message
    var statusMessage: String {
        if !isTTSEnabled {
            return "TTS Disabled"
        } else if !canSpeak {
            return "TTS Unavailable"
        } else if isSpeaking {
            return isPaused ? "Paused" : "Speaking"
        } else {
            return "Ready"
        }
    }
    
    /// Returns available voice names for UI display
    var voiceNames: [String] {
        return availableVoices.map { "\($0.name) (\($0.language))" }
    }
    
    /// Finds a voice by its display name
    func findVoice(byName name: String) -> AVSpeechSynthesisVoice? {
        return availableVoices.first { voice in
            "\(voice.name) (\(voice.language))" == name
        }
    }
}

// MARK: - Preview Support

extension TTSManager {
    static func preview() -> TTSManager {
        let manager = TTSManager()
        manager.isTTSEnabled = true
        return manager
    }
    
    static func previewSpeaking() -> TTSManager {
        let manager = TTSManager()
        manager.isTTSEnabled = true
        manager.isSpeaking = true
        return manager
    }
}
