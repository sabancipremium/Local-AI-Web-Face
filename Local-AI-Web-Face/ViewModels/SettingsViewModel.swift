// SettingsViewModel.swift
// Local-AI-Web-Face
//
// ViewModel for settings interface

import Foundation
import Combine
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Model Management Properties
    
    @Published var availableModels: [String] = []
    @Published var selectedModel: String? = nil
    @Published var isModelListLoading: Bool = false
    @Published var modelManagementError: String? = nil
    @Published var pullProgress: String? = nil
    @Published var isConnected: Bool = false
    
    // MARK: - TTS Properties (Phase 1 - Basic)
    
    @Published var isTTSEnabled: Bool = true
    @Published var selectedVoiceIdentifier: String? = nil
    @Published var speechRate: Float = 0.5
    
    // MARK: - App Settings
    
    @Published var ollamaURL: String = "http://localhost:11434"
    @Published var enableNotifications: Bool = true
    @Published var enableAutoScroll: Bool = true
    @Published var maxChatHistory: Int = 100
    
    // MARK: - Dependencies
    
    private let modelManager: ModelManager
    private let ttsManager: TTSManager?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private struct Keys {
        static let ttsEnabled = "ttsEnabled"
        static let selectedVoice = "selectedVoiceIdentifier"
        static let speechRate = "speechRate"
        static let ollamaURL = "ollamaURL"
        static let enableNotifications = "enableNotifications"
        static let enableAutoScroll = "enableAutoScroll"
        static let maxChatHistory = "maxChatHistory"
    }
    
    // MARK: - Initialization
    
    init(modelManager: ModelManager, ttsManager: TTSManager? = nil) {
        self.modelManager = modelManager
        self.ttsManager = ttsManager
        
        setupObservations()
        loadCurrentSettings()
    }
    
    // MARK: - Setup
    
    private func setupObservations() {
        // Observe ModelManager changes
        modelManager.$availableModels
            .assign(to: \.availableModels, on: self)
            .store(in: &cancellables)
        
        modelManager.$selectedModelName
            .assign(to: \.selectedModel, on: self)
            .store(in: &cancellables)
        
        modelManager.$isLoading
            .assign(to: \.isModelListLoading, on: self)
            .store(in: &cancellables)
        
        modelManager.$errorMessage
            .assign(to: \.modelManagementError, on: self)
            .store(in: &cancellables)
        
        modelManager.$pullProgress
            .assign(to: \.pullProgress, on: self)
            .store(in: &cancellables)
        
        modelManager.$isConnected
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
        
        // Observe TTS settings changes and save them
        $isTTSEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.ttsEnabled)
                self?.ttsManager?.toggleTTSEnabled(enabled: value)
            }
            .store(in: &cancellables)
        
        $selectedVoiceIdentifier
            .dropFirst()
            .sink { [weak self] value in
                if let value = value {
                    self?.userDefaults.set(value, forKey: Keys.selectedVoice)
                    self?.ttsManager?.selectVoice(identifier: value)
                }
            }
            .store(in: &cancellables)
        
        $speechRate
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.speechRate)
                self?.ttsManager?.setSpeechRate(rate: value)
            }
            .store(in: &cancellables)
        
        // Save other settings changes
        $enableNotifications
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.enableNotifications)
            }
            .store(in: &cancellables)
        
        $enableAutoScroll
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.enableAutoScroll)
            }
            .store(in: &cancellables)
        
        $maxChatHistory
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.maxChatHistory)
            }
            .store(in: &cancellables)
    }
    
    private func loadCurrentSettings() {
        // Load TTS settings
        isTTSEnabled = userDefaults.bool(forKey: Keys.ttsEnabled, defaultValue: true)
        selectedVoiceIdentifier = userDefaults.string(forKey: Keys.selectedVoice)
        speechRate = userDefaults.float(forKey: Keys.speechRate, defaultValue: 0.5)
        
        // Load app settings
        ollamaURL = userDefaults.string(forKey: Keys.ollamaURL) ?? "http://localhost:11434"
        enableNotifications = userDefaults.bool(forKey: Keys.enableNotifications, defaultValue: true)
        enableAutoScroll = userDefaults.bool(forKey: Keys.enableAutoScroll, defaultValue: true)
        maxChatHistory = userDefaults.integer(forKey: Keys.maxChatHistory, defaultValue: 100)
        
        // Load initial model data
        Task {
            await fetchAvailableModels()
        }
    }
    
    // MARK: - Model Management
    
    func fetchAvailableModels() async {
        await modelManager.fetchAvailableModels()
    }
    
    func selectModel(modelName: String) {
        modelManager.selectModel(modelName: modelName)
    }
    
    func refreshModels() async {
        await modelManager.refreshConnection()
    }
    
    func pullModel(modelName: String) async {
        await modelManager.pullModel(modelName: modelName)
    }
    
    func deleteModel(modelName: String) async {
        await modelManager.deleteModel(modelName: modelName)
    }
    
    // MARK: - TTS Management
    
    func toggleTTS() {
        isTTSEnabled.toggle()
    }
    
    func testTTS() {
        guard let ttsManager = ttsManager, isTTSEnabled else { return }
        ttsManager.speak(text: "Hello! This is a test of the text-to-speech system.")
    }
    
    // MARK: - Connection Management
    
    func testConnection() async {
        await modelManager.checkConnection()
    }
    
    func resetToDefaults() {
        // Reset TTS settings
        isTTSEnabled = true
        selectedVoiceIdentifier = nil
        speechRate = 0.5
        
        // Reset app settings
        ollamaURL = "http://localhost:11434"
        enableNotifications = true
        enableAutoScroll = true
        maxChatHistory = 100
        
        // Clear stored settings
        userDefaults.removeObject(forKey: Keys.ttsEnabled)
        userDefaults.removeObject(forKey: Keys.selectedVoice)
        userDefaults.removeObject(forKey: Keys.speechRate)
        userDefaults.removeObject(forKey: Keys.ollamaURL)
        userDefaults.removeObject(forKey: Keys.enableNotifications)
        userDefaults.removeObject(forKey: Keys.enableAutoScroll)
        userDefaults.removeObject(forKey: Keys.maxChatHistory)
    }
    
    // MARK: - Computed Properties
    
    var hasModelsAvailable: Bool {
        return !availableModels.isEmpty
    }
    
    var canPullModels: Bool {
        return isConnected && !isModelListLoading
    }
    
    var connectionStatus: String {
        if !isConnected {
            return "Disconnected"
        } else if isModelListLoading {
            return "Loading..."
        } else if let error = modelManagementError {
            return "Error: \(error)"
        } else if let progress = pullProgress {
            return progress
        } else if hasModelsAvailable {
            return "Connected (\(availableModels.count) models)"
        } else {
            return "Connected (no models)"
        }
    }
    
    var settingsValid: Bool {
        return !ollamaURL.isEmpty && maxChatHistory > 0
    }
}

// MARK: - Extensions

extension SettingsViewModel {
    
    /// Returns available model names for popular models that can be pulled
    var popularModels: [String] {
        return [
            "llama3.2",
            "llama3.2:1b",
            "llama3.1",
            "codellama",
            "mistral",
            "phi3",
            "gemma2",
            "qwen2.5",
            "deepseek-coder"
        ].filter { !availableModels.contains($0) }
    }
    
    /// Export current settings as a dictionary
    var exportedSettings: [String: Any] {
        return [
            "ttsEnabled": isTTSEnabled,
            "selectedVoice": selectedVoiceIdentifier ?? "",
            "speechRate": speechRate,
            "ollamaURL": ollamaURL,
            "enableNotifications": enableNotifications,
            "enableAutoScroll": enableAutoScroll,
            "maxChatHistory": maxChatHistory,
            "selectedModel": selectedModel ?? ""
        ]
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
    
    func float(forKey key: String, defaultValue: Float) -> Float {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return float(forKey: key)
    }
    
    func integer(forKey key: String, defaultValue: Int) -> Int {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return integer(forKey: key)
    }
}

// MARK: - Preview Support

extension SettingsViewModel {
    static func preview() -> SettingsViewModel {
        let manager = ModelManager.preview()
        let viewModel = SettingsViewModel(modelManager: manager)
        viewModel.isConnected = true
        return viewModel
    }
}
