// OllamaService.swift
// Local-AI-Web-Face
//
// Service for interacting with the local Ollama API

import Foundation
import Combine

// MARK: - Data Structures

struct ChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
    
    init(model: String, messages: [OllamaMessage], stream: Bool = true) {
        self.model = model
        self.messages = messages
        self.stream = stream
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct ChatResponseChunk: Codable {
    let model: String?
    let createdAt: String?
    let message: OllamaMessage?
    let done: Bool
    
    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case message
        case done
    }
}

struct OllamaTag: Codable, Hashable {
    let name: String
    let size: Int64?
    let digest: String?
    let modifiedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case size
        case digest
        case modifiedAt = "modified_at"
    }
}

struct OllamaTagsResponse: Codable {
    let models: [OllamaTag]
}

struct PullRequest: Codable {
    let name: String
    let stream: Bool
    
    init(name: String, stream: Bool = true) {
        self.name = name
        self.stream = stream
    }
}

struct OllamaPullStatus: Codable {
    let status: String
    let digest: String?
    let total: Int64?
    let completed: Int64?
    
    var progressPercentage: Double? {
        guard let total = total, let completed = completed, total > 0 else { return nil }
        return Double(completed) / Double(total) * 100.0
    }
}

struct DeleteRequest: Codable {
    let name: String
}

// MARK: - Errors

enum OllamaError: LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    case streamingError(String)
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Ollama API URL"
        case .noData:
            return "No data received from Ollama"
        case .invalidResponse:
            return "Invalid response from Ollama API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .connectionFailed:
            return "Failed to connect to Ollama. Make sure Ollama is running on localhost:11434"
        }
    }
}

// MARK: - OllamaService

@MainActor
class OllamaService: ObservableObject {
    // MARK: - Properties
    
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    private let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    init(baseURL: String = "http://localhost:11434/api") {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid Ollama base URL: \(baseURL)")
        }
        
        self.baseURL = url
        self.urlSession = URLSession.shared
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        
        // Test connection on initialization
        Task {
            await checkConnection()
        }
    }
    
    // MARK: - Connection Management
    
    func checkConnection() async {
        do {
            _ = try await getAvailableModels()
            isConnected = true
            connectionError = nil
        } catch {
            isConnected = false
            connectionError = error.localizedDescription
        }
    }
    
    // MARK: - Chat API
    
    func sendChatMessage(
        prompt: String,
        model: String,
        history: [ChatMessage] = []
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Convert ChatMessage history to OllamaMessage format
                    var messages: [OllamaMessage] = history.map { chatMessage in
                        OllamaMessage(
                            role: chatMessage.sender == .user ? "user" : "assistant",
                            content: chatMessage.content
                        )
                    }
                    
                    // Add the new user message
                    messages.append(OllamaMessage(role: "user", content: prompt))
                    
                    let request = ChatRequest(model: model, messages: messages, stream: true)
                    let requestData = try encoder.encode(request)
                    
                    var urlRequest = URLRequest(url: baseURL.appendingPathComponent("chat"))
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData
                    
                    let (data, response) = try await urlSession.data(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: OllamaError.httpError(httpResponse.statusCode))
                        return
                    }
                    
                    // Parse streaming response
                    let dataString = String(data: data, encoding: .utf8) ?? ""
                    let lines = dataString.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedLine.isEmpty else { continue }
                        
                        do {
                            let chunk = try decoder.decode(ChatResponseChunk.self, from: Data(trimmedLine.utf8))
                            
                            if let content = chunk.message?.content, !content.isEmpty {
                                continuation.yield(content)
                            }
                            
                            if chunk.done {
                                continuation.finish()
                                return
                            }
                        } catch {
                            // Skip malformed JSON chunks but continue processing
                            continue
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Model Management API
    
    func getAvailableModels() async throws -> [String] {
        let url = baseURL.appendingPathComponent("tags")
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OllamaError.httpError(httpResponse.statusCode)
            }
            
            let tagsResponse = try decoder.decode(OllamaTagsResponse.self, from: data)
            return tagsResponse.models.map { $0.name }
            
        } catch let error as DecodingError {
            throw OllamaError.decodingError(error)
        } catch {
            throw OllamaError.networkError(error)
        }
    }
    
    func getDetailedModels() async throws -> [OllamaTag] {
        let url = baseURL.appendingPathComponent("tags")
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OllamaError.httpError(httpResponse.statusCode)
            }
            
            let tagsResponse = try decoder.decode(OllamaTagsResponse.self, from: data)
            return tagsResponse.models
            
        } catch let error as DecodingError {
            throw OllamaError.decodingError(error)
        } catch {
            throw OllamaError.networkError(error)
        }
    }
    
    func pullModel(modelName: String) -> AsyncThrowingStream<OllamaPullStatus, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = PullRequest(name: modelName, stream: true)
                    let requestData = try encoder.encode(request)
                    
                    var urlRequest = URLRequest(url: baseURL.appendingPathComponent("pull"))
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData
                    
                    let (data, response) = try await urlSession.data(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: OllamaError.httpError(httpResponse.statusCode))
                        return
                    }
                    
                    // Parse streaming response
                    let dataString = String(data: data, encoding: .utf8) ?? ""
                    let lines = dataString.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedLine.isEmpty else { continue }
                        
                        do {
                            let status = try decoder.decode(OllamaPullStatus.self, from: Data(trimmedLine.utf8))
                            continuation.yield(status)
                            
                            // Check if this is the final status
                            if status.status.contains("success") || status.status.contains("complete") {
                                continuation.finish()
                                return
                            }
                        } catch {
                            // Skip malformed JSON but continue processing
                            continue
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func deleteModel(modelName: String) async throws {
        let request = DeleteRequest(name: modelName)
        let requestData = try encoder.encode(request)
        
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("delete"))
        urlRequest.httpMethod = "DELETE"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestData
        
        do {
            let (_, response) = try await urlSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw OllamaError.httpError(httpResponse.statusCode)
            }
            
        } catch {
            throw OllamaError.networkError(error)
        }
    }
    
    // MARK: - Utility Methods
    
    func formatModelSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
