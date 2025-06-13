// ChatViewModel.swift
// Local-AI-Web-Face
//
// ViewModel for chat interface

import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var currentModelName: String = ""
    @Published var errorMessage: String? = nil
    @Published var isConnected: Bool = false
    
    // MARK: - Dependencies
    
    private let ollamaService: OllamaService
    private let modelManager: ModelManager
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentStreamTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(ollamaService: OllamaService, modelManager: ModelManager) {
        self.ollamaService = ollamaService
        self.modelManager = modelManager
        
        setupObservations()
        loadInitialState()
    }
    
    // MARK: - Setup
    
    private func setupObservations() {
        // Observe model manager changes
        modelManager.$selectedModelName
            .compactMap { $0 }
            .assign(to: \.currentModelName, on: self)
            .store(in: &cancellables)
        
        // Observe connection status
        ollamaService.$isConnected
            .sink { [weak self] connected in
                NSLog("ChatViewModel: Connection status changed to: \(connected)")
                self?.isConnected = connected
            }
            .store(in: &cancellables)
        
        // Clear error message when input changes
        $inputText
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialState() {
        currentModelName = modelManager.selectedModelName ?? ""
        isConnected = ollamaService.isConnected
        
        NSLog("ChatViewModel: Initial state - model: '\(currentModelName)', connected: \(isConnected)")
        
        // Add welcome message if no messages exist
        if messages.isEmpty {
            addWelcomeMessage()
        }
    }
    
    // MARK: - Message Management
    
    func sendMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else { return }
        guard !isLoading else { return }
        guard !currentModelName.isEmpty else {
            errorMessage = "Please select a model first"
            return
        }
        guard isConnected else {
            errorMessage = "Not connected to Ollama. Please check if Ollama is running."
            return
        }
        
        // Clear previous errors
        errorMessage = nil
        
        // Create user message
        let userMessage = ChatMessage.userMessage(trimmedInput)
        messages.append(userMessage)
        
        // Clear input and set loading state
        inputText = ""
        isLoading = true
        
        // Create placeholder bot message
        let botMessage = ChatMessage.loadingBotMessage()
        messages.append(botMessage)
        
        // Start streaming response
        currentStreamTask = Task {
            await streamBotResponse(userPrompt: trimmedInput, botMessageId: botMessage.id)
        }
    }
    
    private func streamBotResponse(userPrompt: String, botMessageId: UUID) async {
        do {
            var responseContent = ""
            
            for try await chunk in ollamaService.sendChatMessage(
                prompt: userPrompt,
                model: currentModelName,
                history: getConversationHistory()
            ) {
                responseContent += chunk
                
                // Update the bot message with accumulated content
                if let index = messages.firstIndex(where: { $0.id == botMessageId }) {
                    messages[index].updateContent(responseContent)
                }
            }
            
            // Finish loading state
            if let index = messages.firstIndex(where: { $0.id == botMessageId }) {
                messages[index].finishLoading()
            }
            
            isLoading = false
            
        } catch {
            // Handle streaming error
            if let index = messages.firstIndex(where: { $0.id == botMessageId }) {
                messages[index].markAsError(error.localizedDescription)
            }
            
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func stopGeneration() {
        currentStreamTask?.cancel()
        currentStreamTask = nil
        isLoading = false
        
        // Remove loading message if it exists
        if let lastMessage = messages.last, lastMessage.isLoading {
            messages.removeLast()
        }
    }
    
    func clearChat() {
        currentStreamTask?.cancel()
        currentStreamTask = nil
        messages.removeAll()
        isLoading = false
        errorMessage = nil
        
        addWelcomeMessage()
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isFromUser }) else { return }
        
        // Remove the last bot message if it was an error
        if let lastBotMessage = messages.last, lastBotMessage.isFromBot && lastBotMessage.isError {
            messages.removeLast()
        }
        
        // Resend the last user message
        inputText = lastUserMessage.content
        sendMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeContent = currentModelName.isEmpty ?
            "Welcome to Local AI Chat! Please select a model to get started." :
            "Hello! I'm ready to chat using the \(currentModelName) model. How can I help you today?"
        
        let welcomeMessage = ChatMessage.botMessage(welcomeContent)
        messages.append(welcomeMessage)
    }
    
    // MARK: - Helper Methods
    
    private func getConversationHistory() -> [ChatMessage] {
        // Return all messages except loading and error messages
        return messages.filter { !$0.isLoading && !$0.isError }
    }
    
    var canSendMessage: Bool {
        return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !isLoading &&
               !currentModelName.isEmpty &&
               isConnected
    }
    
    var hasMessages: Bool {
        return messages.count > 1 // More than just the welcome message
    }
    
    var lastBotMessage: ChatMessage? {
        return messages.last(where: { $0.isFromBot && !$0.isLoading })
    }
    
    // MARK: - Model Management Integration
    
    func refreshConnection() async {
        await modelManager.refreshConnection()
    }
    
    func updateModelSelection(_ modelName: String) {
        modelManager.selectModel(modelName: modelName)
        
        // Add a message about the model change
        let changeMessage = ChatMessage.botMessage("I'm now using the \(modelName) model. How can I help you?")
        messages.append(changeMessage)
    }
}

// MARK: - Extensions

extension ChatViewModel {
    
    /// Statistics about the current chat session
    var chatStatistics: (messageCount: Int, userMessages: Int, botMessages: Int, wordCount: Int) {
        let userMessages = messages.filter { $0.isFromUser }.count
        let botMessages = messages.filter { $0.isFromBot && !$0.isLoading && !$0.isError }.count
        let totalWords = messages.reduce(0) { $0 + $1.wordCount }
        
        return (messages.count, userMessages, botMessages, totalWords)
    }
    
    /// Returns the current conversation context for display
    var conversationContext: String {
        let userMsgCount = messages.filter { $0.isFromUser }.count
        let botMsgCount = messages.filter { $0.isFromBot && !$0.isLoading }.count
        
        if userMsgCount == 0 {
            return "No conversation yet"
        } else {
            return "\(userMsgCount) messages • \(botMsgCount) responses"
        }
    }
}

// MARK: - Preview Support

extension ChatViewModel {
    static func preview() -> ChatViewModel {
        let service = OllamaService()
        let manager = ModelManager.preview()
        let viewModel = ChatViewModel(ollamaService: service, modelManager: manager)
        viewModel.messages = ChatMessage.sampleMessages
        viewModel.currentModelName = "llama3.2"
        viewModel.isConnected = true
        return viewModel
    }
    
    static func previewWithLoading() -> ChatViewModel {
        let viewModel = preview()
        viewModel.isLoading = true
        viewModel.messages.append(ChatMessage.loadingBotMessage())
        return viewModel
    }
    
    static func previewWithError() -> ChatViewModel {
        let viewModel = preview()
        viewModel.errorMessage = "Connection failed"
        viewModel.messages.append(ChatMessage.errorMessage("Network timeout"))
        return viewModel
    }
}
