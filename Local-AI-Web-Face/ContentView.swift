//
//  ContentView.swift
//  Local-AI-Web-Face
//
//  Created by Ahmet Ekiz on 12.06.2025.
//

import SwiftUI

struct ContentView: View {
    // Environment Objects injected from Local_AI_Web_FaceApp
    @EnvironmentObject var modelManager: ModelManager
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    // Local UI state
    @State private var showingSettings: Bool = false
    @State private var selectedModel: String = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Local AI Chat")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Ollama-Powered Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Model Selection Section
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Model", systemImage: "cpu")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if modelManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading models...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select Model", selection: $selectedModel) {
                            ForEach(modelManager.availableModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .disabled(modelManager.availableModels.isEmpty)
                        
                        if modelManager.availableModels.isEmpty {
                            Text("No models available")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Button("Refresh Models") {
                        Task {
                            await modelManager.fetchAvailableModels()
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Status Section
                VStack(alignment: .leading, spacing: 8) {
                    Label("Status", systemImage: "circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Circle()
                            .fill(chatViewModel.isConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(chatViewModel.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !selectedModel.isEmpty {
                        HStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Model: \(selectedModel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if ttsManager.isTTSEnabled {
                        HStack {
                            Circle()
                                .fill(ttsManager.isSpeaking ? .orange : .green)
                                .frame(width: 8, height: 8)
                            Text(ttsManager.isSpeaking ? "Speaking..." : "TTS Ready")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Settings Button
                Button(action: { showingSettings = true }) {
                    Label("Settings", systemImage: "gear")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(minWidth: 250, idealWidth: 280)
            .background(Color(NSColor.controlBackgroundColor))
            
        } detail: {
            // Main Content Area
            if selectedModel.isEmpty || modelManager.availableModels.isEmpty {
                // Welcome/Setup View
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 64))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("Welcome to Local AI Chat")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your privacy-focused AI assistant powered by Ollama")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    if modelManager.availableModels.isEmpty && !modelManager.isLoading {
                        VStack(spacing: 16) {
                            Text("No models found")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            VStack(spacing: 8) {
                                Text("To get started:")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. Install Ollama: brew install ollama")
                                    Text("2. Pull a model: ollama pull llama3.2")
                                    Text("3. Start Ollama: ollama serve")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button("Refresh Models") {
                                Task {
                                    await modelManager.fetchAvailableModels()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    } else if !selectedModel.isEmpty {
                        Text("Select a model from the sidebar to start chatting")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                
            } else {
                // Chat Interface
                HSplitView {
                    ChatView()
                        .frame(minWidth: 400)
                    
                    // Avatar Panel (Phase 3 feature)
                    if ttsManager.isTTSEnabled {
                        AvatarView(ttsManager: ttsManager)
                            .frame(width: 280)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
            }
            .frame(minWidth: 600, minHeight: 500)
        }
        .onAppear {
            Task {
                await modelManager.fetchAvailableModels()
                if let firstModel = modelManager.availableModels.first {
                    selectedModel = firstModel
                }
            }
        }
        .onChange(of: selectedModel) { _, newModel in
            if !newModel.isEmpty {
                chatViewModel.currentModelName = newModel
                modelManager.selectModel(modelName: newModel)
            }
        }
        .onChange(of: modelManager.selectedModelName) { _, newModel in
            if let newModel = newModel, newModel != selectedModel {
                selectedModel = newModel
            }
        }
    }
}

#Preview {
    ContentView()
}
