// SettingsView.swift
// Local-AI-Web-Face
//
// Settings interface view

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingPullSheet = false
    @State private var modelToPull = ""
    
    var body: some View {
        Form {
            // Connection Section
            ConnectionSection()
            
            // Model Management Section
            ModelManagementSection()
            
            // TTS Settings Section
            TTSSection()
            
            // App Settings Section
            AppSettingsSection()
            
            // Actions Section
            ActionsSection()
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPullSheet) {
            PullModelSheet(modelToPull: $modelToPull)
        }
    }
}

// MARK: - Connection Section

struct ConnectionSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Section("Connection") {
            HStack {
                Text("Status")
                Spacer()
                Text(settingsViewModel.connectionStatus)
                    .foregroundColor(settingsViewModel.isConnected ? .green : .red)
            }
            
            HStack {
                TextField("Ollama URL", text: $settingsViewModel.ollamaURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Test") {
                    Task {
                        await settingsViewModel.testConnection()
                    }
                }
                .disabled(settingsViewModel.isModelListLoading)
            }
            
            if !settingsViewModel.isConnected {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ollama Setup Instructions:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("1. Install: brew install ollama")
                    Text("2. Start: ollama serve")
                    Text("3. Pull a model: ollama pull llama3.2")
                    
                    Link("Visit Ollama.ai for more info", destination: URL(string: "https://ollama.ai")!)
                        .font(.caption)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Model Management Section

struct ModelManagementSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showingDeleteConfirmation = false
    @State private var modelToDelete = ""
    
    var body: some View {
        Section("Model Management") {
            if settingsViewModel.isModelListLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading models...")
                        .foregroundColor(.secondary)
                }
            } else {
                // Current Model Selection
                Picker("Current Model", selection: $settingsViewModel.selectedModel) {
                    Text("No model selected").tag(nil as String?)
                    ForEach(settingsViewModel.availableModels, id: \.self) { modelName in
                        Text(modelName).tag(modelName as String?)
                    }
                }
                .onChange(of: settingsViewModel.selectedModel) { _, newValue in
                    if let newModel = newValue {
                        settingsViewModel.selectModel(modelName: newModel)
                    }
                }
                
                // Available Models List
                if settingsViewModel.hasModelsAvailable {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Models (\(settingsViewModel.availableModels.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(settingsViewModel.availableModels, id: \.self) { model in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(model)
                                        .font(.body)
                                    if model == settingsViewModel.selectedModel {
                                        Text("Currently selected")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                Button("Delete") {
                                    modelToDelete = model
                                    showingDeleteConfirmation = true
                                }
                                .foregroundColor(.red)
                                .disabled(settingsViewModel.isModelListLoading)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Actions
                HStack {
                    Button("Refresh Models") {
                        Task {
                            await settingsViewModel.refreshModels()
                        }
                    }
                    .disabled(settingsViewModel.isModelListLoading)
                    
                    Spacer()
                    
                    Button("Pull New Model") {
                        // This would show a sheet with popular models
                    }
                    .disabled(!settingsViewModel.canPullModels)
                }
            }
            
            // Pull Progress
            if let progress = settingsViewModel.pullProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(progress)
                        .foregroundColor(.blue)
                }
            }
            
            // Error Display
            if let error = settingsViewModel.modelManagementError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .confirmationDialog("Delete Model", isPresented: $showingDeleteConfirmation) {
            Button("Delete \(modelToDelete)", role: .destructive) {
                Task {
                    await settingsViewModel.deleteModel(modelName: modelToDelete)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \(modelToDelete)? This action cannot be undone.")
        }
    }
}

// MARK: - TTS Section

struct TTSSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Section("Text-to-Speech") {
            Toggle("Enable TTS", isOn: $settingsViewModel.isTTSEnabled)
            
            if settingsViewModel.isTTSEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speech Rate")
                        Spacer()
                        Text("\(Int(settingsViewModel.speechRate * 100))%")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $settingsViewModel.speechRate, in: 0.1...1.0)
                }
                
                Button("Test Voice") {
                    settingsViewModel.testTTS()
                }
                .disabled(!settingsViewModel.isTTSEnabled)
            }
        }
    }
}

// MARK: - App Settings Section

struct AppSettingsSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Section("App Settings") {
            Toggle("Enable Notifications", isOn: $settingsViewModel.enableNotifications)
            
            Toggle("Auto-scroll Chat", isOn: $settingsViewModel.enableAutoScroll)
            
            HStack {
                Text("Max Chat History")
                Spacer()
                TextField("", value: $settingsViewModel.maxChatHistory, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                Text("messages")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Actions Section

struct ActionsSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        Section("Actions") {
            Button("Reset to Defaults") {
                settingsViewModel.resetToDefaults()
            }
            .foregroundColor(.orange)
            
            Button("Export Settings") {
                exportSettings()
            }
        }
    }
    
    private func exportSettings() {
        let settings = settingsViewModel.exportedSettings
        // For Phase 1, we'll just print the settings
        // In Phase 2, this could save to a file or copy to clipboard
        print("Exported settings: \(settings)")
    }
}

// MARK: - Pull Model Sheet

struct PullModelSheet: View {
    @Binding var modelToPull: String
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Pull New Model")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a popular model to download:")
                    .foregroundColor(.secondary)
                
                LazyVStack(spacing: 8) {
                    ForEach(settingsViewModel.popularModels, id: \.self) { model in
                        Button(action: {
                            modelToPull = model
                            Task {
                                await settingsViewModel.pullModel(modelName: model)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(model)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "arrow.down.circle")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                HStack {
                    TextField("Custom model name", text: $modelToPull)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Pull") {
                        Task {
                            await settingsViewModel.pullModel(modelName: modelToPull)
                            dismiss()
                        }
                    }
                    .disabled(modelToPull.isEmpty)
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

// MARK: - Preview

#Preview("Settings View") {
    NavigationView {
        SettingsView()
            .environmentObject(SettingsViewModel.preview())
    }
    .frame(width: 600, height: 700)
}

#Preview("Settings View - No Connection") {
    NavigationView {
        SettingsView()
            .environmentObject({
                let vm = SettingsViewModel.preview()
                vm.isConnected = false
                return vm
            }())
    }
    .frame(width: 600, height: 700)
}
