// ModelManager.swift
// Local-AI-Web-Face
//
// Service for managing Ollama models

import Foundation
import Combine

@MainActor
class ModelManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var availableModels: [String] = []
    @Published var selectedModelName: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var pullProgress: String? = nil
    @Published var isConnected: Bool = false
    
    // MARK: - Dependencies
    
    private let ollamaService: OllamaService
    
    // MARK: - Private Properties
    
    private let userDefaultsKeySelectedModel = "selectedOllamaModel"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(ollamaService: OllamaService) {
        self.ollamaService = ollamaService
        loadSelectedModel()
        
        NSLog("ModelManager: Initialized with connection status: \(ollamaService.isConnected)")
        
        // Observe OllamaService connection status
        ollamaService.$isConnected
            .assign(to: \.isConnected, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Model Management
    
    func fetchAvailableModels() async {
        isLoading = true
        errorMessage = nil
        
        NSLog("ModelManager: Starting to fetch available models...")
        
        do {
            let models = try await ollamaService.getAvailableModels()
            availableModels = models.sorted()
            
            NSLog("ModelManager: Successfully fetched \(models.count) models: \(models)")
            
            // If no model is selected and we have models, select the first one
            if selectedModelName == nil && !models.isEmpty {
                selectModel(modelName: models.first!)
                NSLog("ModelManager: Auto-selected first model: \(models.first!)")
            }
            
            // Validate that the selected model still exists
            if let selectedModel = selectedModelName,
               !models.contains(selectedModel) {
                NSLog("ModelManager: Previously selected model '\(selectedModel)' no longer available")
                selectedModelName = nil
                saveSelectedModel()
            }
            
        } catch {
            NSLog("ModelManager: Error fetching models: \(error)")
            errorMessage = error.localizedDescription
            availableModels = []
        }
        
        isLoading = false
    }
    
    func selectModel(modelName: String) {
        selectedModelName = modelName
        saveSelectedModel()
    }
    
    func clearSelectedModel() {
        selectedModelName = nil
        saveSelectedModel()
    }
    
    // MARK: - Model Operations (Phase 2 features, basic implementation for Phase 1)
    
    func pullModel(modelName: String) async {
        isLoading = true
        errorMessage = nil
        pullProgress = "Starting download..."
        
        do {
            for try await status in ollamaService.pullModel(modelName: modelName) {
                if let percentage = status.progressPercentage {
                    pullProgress = "Downloading: \(Int(percentage))%"
                } else {
                    pullProgress = status.status
                }
            }
            
            pullProgress = "Download completed"
            
            // Refresh the models list
            await fetchAvailableModels()
            
            // Select the newly downloaded model
            selectModel(modelName: modelName)
            
        } catch {
            errorMessage = "Failed to download model: \(error.localizedDescription)"
            pullProgress = nil
        }
        
        isLoading = false
        
        // Clear progress after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.pullProgress = nil
        }
    }
    
    func deleteModel(modelName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await ollamaService.deleteModel(modelName: modelName)
            
            // If we deleted the selected model, clear the selection
            if selectedModelName == modelName {
                clearSelectedModel()
            }
            
            // Refresh the models list
            await fetchAvailableModels()
            
        } catch {
            errorMessage = "Failed to delete model: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Persistence
    
    private func saveSelectedModel() {
        if let modelName = selectedModelName {
            UserDefaults.standard.set(modelName, forKey: userDefaultsKeySelectedModel)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKeySelectedModel)
        }
    }
    
    private func loadSelectedModel() {
        selectedModelName = UserDefaults.standard.string(forKey: userDefaultsKeySelectedModel)
    }
    
    // MARK: - Utility Methods
    
    var hasModels: Bool {
        return !availableModels.isEmpty
    }
    
    var hasSelectedModel: Bool {
        return selectedModelName != nil
    }
    
    func isModelSelected(_ modelName: String) -> Bool {
        return selectedModelName == modelName
    }
    
    // MARK: - Connection Management
    
    func checkConnection() async {
        await ollamaService.checkConnection()
    }
    
    // MARK: - Debug Methods
    
    func refreshConnection() async {
        await checkConnection()
        if isConnected {
            await fetchAvailableModels()
        }
    }
}

// MARK: - Extensions

extension ModelManager {
    
    /// Returns a user-friendly status message for the current state
    var statusMessage: String {
        if !isConnected {
            return "Disconnected from Ollama"
        } else if isLoading {
            return "Loading..."
        } else if let error = errorMessage {
            return "Error: \(error)"
        } else if let progress = pullProgress {
            return progress
        } else if availableModels.isEmpty {
            return "No models available"
        } else if let selected = selectedModelName {
            return "Using: \(selected)"
        } else {
            return "Select a model to start"
        }
    }
    
    /// Returns whether the manager is in a ready state (connected with models)
    var isReady: Bool {
        return isConnected && hasModels && hasSelectedModel && !isLoading
    }
    
    /// Returns whether a refresh operation can be performed
    var canRefresh: Bool {
        return !isLoading
    }
}

// MARK: - Sample Data

extension ModelManager {
    static func preview(withModels models: [String] = ["llama3.2", "codellama", "mistral"]) -> ModelManager {
        let service = OllamaService()
        let manager = ModelManager(ollamaService: service)
        manager.availableModels = models
        manager.selectedModelName = models.first
        manager.isConnected = true
        return manager
    }
}
