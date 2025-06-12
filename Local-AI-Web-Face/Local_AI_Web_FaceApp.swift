//
//  Local_AI_Web_FaceApp.swift
//  Local-AI-Web-Face
//
//  Created by Ahmet Ekiz on 12.06.2025.
//

import SwiftUI

@main
struct Local_AI_Web_FaceApp: App {
    // Shared services and managers
    @StateObject private var ollamaService: OllamaService
    @StateObject private var modelManager: ModelManager
    @StateObject private var ttsManager: TTSManager
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    init() {
        // Initialize services first
        let ollamaService = OllamaService()
        let modelManager = ModelManager(ollamaService: ollamaService)
        let ttsManager = TTSManager()
        
        // Initialize ViewModels with their dependencies
        let settingsViewModel = SettingsViewModel(modelManager: modelManager, ttsManager: ttsManager)
        let chatViewModel = ChatViewModel(ollamaService: ollamaService, modelManager: modelManager)
        
        // Assign to StateObjects
        self._ollamaService = StateObject(wrappedValue: ollamaService)
        self._modelManager = StateObject(wrappedValue: modelManager)
        self._ttsManager = StateObject(wrappedValue: ttsManager)
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
        self._chatViewModel = StateObject(wrappedValue: chatViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelManager)
                .environmentObject(ttsManager)
                .environmentObject(settingsViewModel)
                .environmentObject(chatViewModel)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands()
        }
    }
}

// MARK: - App Commands

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Local AI Chat") {
                // Could show about window
            }
        }
        
        CommandGroup(after: .appInfo) {
            Divider()
            Button("Preferences...") {
                // Could open settings window
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        
        CommandGroup(replacing: .help) {
            Button("Local AI Chat Help") {
                if let url = URL(string: "https://ollama.ai") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
