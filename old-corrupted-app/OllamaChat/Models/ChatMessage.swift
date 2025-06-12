import Foundation

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

// Ollama API Response Models
struct OllamaResponse: Codable {
    let model: String
    let createdAt: String
    let message: OllamaMessage
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    
    init(model: String, messages: [ChatMessage]) {
        self.model = model
        self.stream = false
        self.messages = messages.map { message in
            OllamaMessage(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            )
        }
    }
}

struct OllamaModelInfo: Codable {
    let name: String
    let size: Int64
    let digest: String
    let details: ModelDetails?
    
    struct ModelDetails: Codable {
        let format: String?
        let family: String?
        let families: [String]?
        let parameterSize: String?
        let quantizationLevel: String?
        
        enum CodingKeys: String, CodingKey {
            case format
            case family
            case families
            case parameterSize = "parameter_size"
            case quantizationLevel = "quantization_level"
        }
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModelInfo]
}
