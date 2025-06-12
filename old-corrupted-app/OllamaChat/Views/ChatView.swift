import SwiftUI

struct ChatView: View {
    let selectedModel: String
    @EnvironmentObject var ollamaService: OllamaService
    @EnvironmentObject var ttsManager: TTSManager
    @State private var messageText = ""
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Chat with \(selectedModel)")
                        .font(.headline)
                    Text("\(ollamaService.messages.count) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // TTS Toggle
                Button(action: {
                    ttsManager.isEnabled.toggle()
                }) {
                    Image(systemName: ttsManager.isEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .foregroundColor(ttsManager.isEnabled ? .blue : .gray)
                }
                .help(ttsManager.isEnabled ? "Disable Text-to-Speech" : "Enable Text-to-Speech")
                
                // Clear Chat
                Button(action: {
                    ollamaService.clearMessages()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .help("Clear Chat History")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Messages ScrollView
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 16) {
                        ForEach(ollamaService.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isTyping {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding()
                    .onChange(of: ollamaService.messages.count) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if isTyping {
                                proxy.scrollTo("typing", anchor: .bottom)
                            } else if let lastMessage = ollamaService.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isTyping) { typing in
                        if typing {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .background(Color(NSColor.textBackgroundColor))
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .lineLimit(1...5)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                .help("Send Message")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty && !isTyping else { return }
        
        messageText = ""
        isTyping = true
        
        Task {
            await ollamaService.sendMessage(trimmedMessage, model: selectedModel)
            isTyping = false
            
            // TTS for AI response
            if ttsManager.isEnabled, let lastMessage = ollamaService.messages.last, !lastMessage.isUser {
                ttsManager.speak(lastMessage.content)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .frame(width: 20, height: 20)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(message.content)
                            .padding(12)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 28)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .frame(width: 20, height: 20)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
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
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationOffset = -3
        }
    }
}
