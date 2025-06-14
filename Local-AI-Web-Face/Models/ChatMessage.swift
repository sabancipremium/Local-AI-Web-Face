// ChatMessage.swift
// Local-AI-Web-Face
//
// Data model for chat messages

import Foundation

// MARK: - Sender Enum

enum Sender: String, Codable, CaseIterable {
    case user = "user"
    case bot = "bot"
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .bot:
            return "AI"
        }
    }
    
    var isUser: Bool {
        return self == .user
    }
}

// MARK: - ChatMessage Model

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let sender: Sender
    var content: String
    let timestamp: Date
    var isLoading: Bool
    var isError: Bool
    var errorMessage: String?
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        sender: Sender,
        content: String,
        timestamp: Date = Date(),
        isLoading: Bool = false,
        isError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isLoading = isLoading
        self.isError = isError
        self.errorMessage = errorMessage
    }
    
    // MARK: - Convenience Initializers
    
    static func userMessage(_ content: String) -> ChatMessage {
        return ChatMessage(sender: .user, content: content)
    }
    
    static func botMessage(_ content: String) -> ChatMessage {
        return ChatMessage(sender: .bot, content: content)
    }
    
    static func loadingBotMessage() -> ChatMessage {
        return ChatMessage(sender: .bot, content: "", isLoading: true)
    }
    
    static func errorMessage(_ error: String) -> ChatMessage {
        return ChatMessage(
            sender: .bot,
            content: "Sorry, I encountered an error.",
            isError: true,
            errorMessage: error
        )
    }
    
    // MARK: - Computed Properties
    
    var isFromUser: Bool {
        return sender.isUser
    }
    
    var isFromBot: Bool {
        return !sender.isUser
    }
    
    var isEmpty: Bool {
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var displayContent: String {
        let result = isLoading ? "Thinking..." : content
        NSLog("[ChatMessage] displayContent for ID \(id): isLoading=\(isLoading), content length=\(content.count), returning: '\(result.prefix(50))...'")
        return result
    }
    
    // MARK: - Methods
    
    mutating func updateContent(_ newContent: String) {
        NSLog("[ChatMessage] updateContent called for ID \(id), old content length: \(content.count), new content length: \(newContent.count), was loading: \(isLoading)")
        self.content = newContent
        // Don't automatically set isLoading = false here - let the streaming finish control this
        NSLog("[ChatMessage] updateContent completed, content updated but keeping loading state: \(isLoading)")
    }
    
    mutating func appendContent(_ additionalContent: String) {
        NSLog("[ChatMessage] appendContent called for ID \(id), additional content: '\(additionalContent)'")
        if isLoading {
            self.content = additionalContent
            self.isLoading = false
        } else {
            self.content += additionalContent
        }
        NSLog("[ChatMessage] appendContent completed, total content length: \(content.count)")
    }
    
    mutating func markAsError(_ errorMessage: String) {
        NSLog("[ChatMessage] markAsError called for ID \(id), error: \(errorMessage)")
        self.isError = true
        self.isLoading = false
        self.errorMessage = errorMessage
        if self.content.isEmpty {
            self.content = "Sorry, I encountered an error."
        }
        NSLog("[ChatMessage] markAsError completed")
    }
    
    mutating func finishLoading() {
        NSLog("[ChatMessage] finishLoading called for ID \(id), was loading: \(isLoading)")
        self.isLoading = false
        NSLog("[ChatMessage] finishLoading completed, isLoading now: \(isLoading)")
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Extensions

extension ChatMessage {
    
    /// Returns a formatted timestamp string for display
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
    
    /// Returns a relative time string (e.g., "2 minutes ago")
    var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    /// Returns the word count of the message content
    var wordCount: Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
}

// MARK: - Sample Data (for previews and testing)

extension ChatMessage {
    static let sampleMessages: [ChatMessage] = [
        ChatMessage.userMessage("Hello! Can you help me with Swift programming?"),
        ChatMessage.botMessage("Of course! I'd be happy to help you with Swift programming. What specific topic or question do you have?"),
        ChatMessage.userMessage("How do I create a simple SwiftUI view?"),
        ChatMessage.botMessage("Here's a simple SwiftUI view example:\n\n```swift\nstruct ContentView: View {\n    var body: some View {\n        Text(\"Hello, World!\")\n            .padding()\n    }\n}\n```\n\nThis creates a basic view with text and padding."),
        ChatMessage.userMessage("That's helpful, thank you!")
    ]
    
    static let loadingSample = ChatMessage.loadingBotMessage()
    static let errorSample = ChatMessage.errorMessage("Network connection failed")
}
