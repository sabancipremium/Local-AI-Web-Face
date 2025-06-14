// ChatView.swift
// Local-AI-Web-Face
//
// Main chat interface view

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var ttsManager: TTSManager
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            ChatHeaderView()
            
            Divider()
            
            // Messages Area
            MessagesScrollView()
            
            Divider()
            
            // Input Area
            ChatInputView()
        }
        .onAppear {
            isInputFocused = true
        }
    }
}

// MARK: - Chat Header

struct ChatHeaderView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat with \(chatViewModel.currentModelName.isEmpty ? "AI" : chatViewModel.currentModelName)")
                    .font(.headline)
                
                Text(chatViewModel.conversationContext)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Connection Status
            HStack(spacing: 4) {
                Circle()
                    .fill(chatViewModel.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(chatViewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Clear Chat Button
            Button(action: chatViewModel.clearChat) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .help("Clear Chat History")
            .disabled(chatViewModel.isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Messages Scroll View

struct MessagesScrollView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatViewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: chatViewModel.messages.count) { _, _ in
                if settingsViewModel.enableAutoScroll {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let lastMessage = chatViewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text(message.displayContent)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .textSelection(.enabled)
                        
                        if message.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    Text(message.formattedTimestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        // AI Avatar
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(message.displayContent)
                                    .padding(12)
                                    .background(message.isError ? Color.red.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(message.isError ? .red : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .textSelection(.enabled)
                                
                                if message.isLoading {
                                    TypingIndicatorView()
                                }
                            }
                            
                            if message.isError, let errorMessage = message.errorMessage {
                                Text("Error: \(errorMessage)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    
                    HStack {
                        Text(message.formattedTimestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 36)
                        
                        if message.isError {
                            Button("Retry") {
                                // This would need to be passed to the view model
                                // For now, it's a placeholder
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(8)
        .onAppear {
            animationOffset = -3
        }
    }
}

// MARK: - Chat Input View

struct ChatInputView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Error Message
            if let errorMessage = chatViewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Dismiss") {
                        chatViewModel.errorMessage = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Input Row
            HStack(spacing: 12) {
                TextField("Type your message...", text: $chatViewModel.inputText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .onSubmit {
                        if chatViewModel.canSendMessage {
                            chatViewModel.sendMessage()
                        }
                    }
                    .disabled(chatViewModel.currentModelName.isEmpty)
                
                if chatViewModel.isLoading {
                    Button(action: chatViewModel.stopGeneration) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .help("Stop Generation")
                    
                } else {
                    Button(action: chatViewModel.sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(chatViewModel.canSendMessage ? Color.blue : Color.gray)
                            .clipShape(Circle())
                    }
                    .disabled(!chatViewModel.canSendMessage)
                    .help("Send Message")
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            isInputFocused = true
        }
    }
}

// MARK: - Preview

#Preview("Chat View") {
    ChatView()
        .environmentObject(ChatViewModel.preview())
        .environmentObject(SettingsViewModel.preview())
        .frame(width: 600, height: 800)
}

#Preview("Chat View - Loading") {
    ChatView()
        .environmentObject(ChatViewModel.previewWithLoading())
        .environmentObject(SettingsViewModel.preview())
        .frame(width: 600, height: 800)
}

#Preview("Chat View - Error") {
    ChatView()
        .environmentObject(ChatViewModel.previewWithError())
        .environmentObject(SettingsViewModel.preview())
        .frame(width: 600, height: 800)
}

struct MessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !message.isFromUser {
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "cpu")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                    .padding(.leading, 5)
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                if message.isLoading && message.content.isEmpty && !message.isError {
                    // Only show "Thinking..." if content is empty and it's loading and not an error
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        Text("Thinking...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                    .background(message.isFromUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2))
                    .cornerRadius(10)
                } else if message.isError {
                    Text("Error: \(message.content)")
                        .padding(10)
                        .background(Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .textSelection(.enabled)
                } else {
                    Text(message.content.isEmpty && !message.isFromUser ? "Receiving..." : message.content) // Show "Receiving..." if content is empty but not the initial "Thinking..." state
                        .padding(10)
                        .background(message.isFromUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.2))
                        .foregroundColor(message.isFromUser ? .white : .primary)
                        .cornerRadius(10)
                        .textSelection(.enabled)
                }
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if message.isFromUser {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "person")
                            .foregroundColor(.white)
                            .font(.caption)
                    )
                    .padding(.trailing, 5)
            }
        }
        .id(message.id) // Important for ScrollViewReader
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
        .padding(.vertical, 2)
    }
}
