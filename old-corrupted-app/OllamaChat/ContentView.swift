import SwiftUI

struct ContentView: View {
    @EnvironmentObject var modelManager: ModelManager
    @EnvironmentObject var ollamaService: OllamaService
    @EnvironmentObject var ttsManager: TTSManager
    @State private var selectedModel: String = ""
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Ollama Chat")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Local AI Assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Model Selection
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Model", systemImage: "cpu")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Select Model", selection: $selectedModel) {
                        ForEach(modelManager.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(modelManager.isLoading)
                    
                    if modelManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading models...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                            .fill(ollamaService.isConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(ollamaService.isConnected ? "Connected" : "Disconnected")
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
            .frame(minWidth: 250)
            .background(Color(NSColor.controlBackgroundColor))
        } detail: {
            // Main Chat View
            if selectedModel.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("Welcome to Ollama Chat")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Select an AI model from the sidebar to start chatting")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if modelManager.availableModels.isEmpty && !modelManager.isLoading {
                        VStack(spacing: 12) {
                            Text("No models found")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            Text("Make sure Ollama is installed and running with at least one model pulled.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Refresh Models") {
                                Task {
                                    await modelManager.loadModels()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ChatView(selectedModel: selectedModel)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            Task {
                await modelManager.loadModels()
                if let firstModel = modelManager.availableModels.first {
                    selectedModel = firstModel
                }
            }
        }
        .onChange(of: selectedModel) { newModel in
            if !newModel.isEmpty {
                ollamaService.selectedModel = newModel
            }
        }
    }
}
