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
            NSLog("[OllamaService] Checking connection to Ollama at: \(baseURL)")
            let models = try await getAvailableModels()
            NSLog("[OllamaService] Connection successful! Found \(models.count) models: \(models)")
            isConnected = true
            connectionError = nil
        } catch {
            NSLog("[OllamaService] Connection failed with error: \(error)")
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
                    NSLog("[OllamaService] Starting chat with model: \(model), prompt: '\(prompt.prefix(50))...'")
                    
                    // Convert ChatMessage history to OllamaMessage format
                    var messages: [OllamaMessage] = history.map { chatMessage in
                        OllamaMessage(
                            role: chatMessage.sender == .user ? "user" : "assistant",
                            content: chatMessage.content
                        )
                    }
                    
                    NSLog("[OllamaService] Converted \(history.count) history messages")
                    
                    // Add the new user message
                    messages.append(OllamaMessage(role: "user", content: prompt))
                    NSLog("[OllamaService] Total messages to send: \(messages.count)")
                    
                    let request = ChatRequest(model: model, messages: messages, stream: true)
                    let requestData = try encoder.encode(request)
                    
                    let chatURL = baseURL.appendingPathComponent("chat")
                    NSLog("[OllamaService] Chat URL: \(chatURL)")
                    
                    var urlRequest = URLRequest(url: chatURL)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData
                    
                    NSLog("[OllamaService] Sending chat request...")
                    
                    // Use URLSession.bytes to handle streaming properly
                    let (asyncBytes, response) = try await urlSession.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        NSLog("[OllamaService] Invalid response type for chat request")
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }
                    
                    NSLog("[OllamaService] Chat request HTTP status: \(httpResponse.statusCode)")
                    
                    guard httpResponse.statusCode == 200 else {
                        NSLog("[OllamaService] Chat request failed with status: \(httpResponse.statusCode)")
                        continuation.finish(throwing: OllamaError.httpError(httpResponse.statusCode))
                        return
                    }
                    
                    NSLog("[OllamaService] Chat request successful, starting to process stream")
                    
                    // Process streaming response line by line
                    var buffer = ""
                    var chunkCount = 0
                    var totalContent = ""
                    
                    for try await byte in asyncBytes {
                        let character = Character(UnicodeScalar(byte))
                        
                        if character == "\n" {
                            // Process complete line
                            let line = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                            buffer = ""
                            
                            guard !line.isEmpty else { continue }
                            
                            chunkCount += 1
                            NSLog("[OllamaService] Processing chat chunk \(chunkCount): \(line.prefix(100))...")
                            
                            do {
                                let chunk = try decoder.decode(ChatResponseChunk.self, from: Data(line.utf8))
                                
                                if let content = chunk.message?.content, !content.isEmpty {
                                    totalContent += content
                                    NSLog("[OllamaService] Yielding content chunk: '\(content)' (total length: \(totalContent.count))")
                                    continuation.yield(content)
                                }
                                
                                if chunk.done {
                                    NSLog("[OllamaService] Chat completed, total chunks: \(chunkCount), total content length: \(totalContent.count)")
                                    continuation.finish()
                                    return
                                }
                            } catch {
                                // Skip malformed JSON chunks but continue processing
                                NSLog("[OllamaService] Failed to decode chat chunk: \(line), error: \(error)")
                                continue
                            }
                        } else {
                            buffer.append(character)
                        }
                    }
                    
                    NSLog("[OllamaService] Chat stream ended, processed \(chunkCount) chunks")
                    continuation.finish()
                    
                } catch {
                    NSLog("[OllamaService] Chat error: \(error)")
                    continuation.finish(throwing: OllamaError.networkError(error))
                }
            }
        }
    }
    
    public func streamChat(messages: [ChatMessage], model: String, completion: @escaping (String?, Bool, Error?) -> Void) {
        Task {
            var streamDidSignalDone = false // To track if completion has been called with isDone=true
            do {
                NSLog("[OllamaService] Starting streamChat with model: \(model), messages count: \(messages.count)")
                
                // Convert ChatMessage history to OllamaMessage format
                let requestMessages = messages.map { chatMessage in
                    OllamaMessage(
                        role: chatMessage.sender == .user ? "user" : "assistant",
                        content: chatMessage.content
                    )
                }
                
                NSLog("[OllamaService] Converted \(requestMessages.count) messages for request")
                
                let request = ChatRequest(model: model, messages: requestMessages, stream: true)
                let requestData = try encoder.encode(request)
                
                let chatURL = baseURL.appendingPathComponent("chat")
                NSLog("[OllamaService] Chat URL: \(chatURL)")
                
                var urlRequest = URLRequest(url: chatURL)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = requestData
                
                NSLog("[OllamaService] Sending streamChat request...")
                
                // Use URLSession.bytes to handle streaming properly
                let (asyncBytes, response) = try await urlSession.bytes(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    NSLog("[OllamaService] Invalid response type for streamChat request")
                    if !streamDidSignalDone {
                        completion(nil, true, OllamaError.invalidResponse)
                        streamDidSignalDone = true
                    }
                    return
                }
                
                NSLog("[OllamaService] StreamChat request HTTP status: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    NSLog("[OllamaService] StreamChat request failed with status: \(httpResponse.statusCode)")
                    if !streamDidSignalDone {
                        completion(nil, true, OllamaError.httpError(httpResponse.statusCode))
                        streamDidSignalDone = true
                    }
                    return
                }
                
                NSLog("[OllamaService] StreamChat request successful, starting to process stream")
                
                // Process streaming response line by line
                var buffer = ""
                var chunkCount = 0
                var totalContent = ""
                
                for try await byte in asyncBytes {
                    let character = Character(UnicodeScalar(byte))
                    
                    if character == "\n" {
                        // Process complete line
                        let line = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                        buffer = ""
                        
                        guard !line.isEmpty else { continue }
                        
                        chunkCount += 1
                        NSLog("[OllamaService] Processing streamChat chunk \(chunkCount): \(line.prefix(100))...")
                        
                        do {
                            let chunk = try decoder.decode(ChatResponseChunk.self, from: Data(line.utf8))
                            
                            if let content = chunk.message?.content, !content.isEmpty {
                                totalContent += content
                                NSLog("[OllamaService] Yielding content chunk: '\(content)' (total length: \(totalContent.count))")
                                completion(content, false, nil)
                            }
                            
                            if chunk.done {
                                NSLog("[OllamaService] Chunk marked done. Signaling completion with isDone=true.")
                                completion(nil, true, nil)
                                streamDidSignalDone = true
                                return // Stream finished successfully
                            }
                        } catch {
                            // Skip malformed JSON chunks but continue processing
                            NSLog("[OllamaService] Failed to decode streamChat chunk: \(line), error: \(error)")
                            continue
                        }
                    } else {
                        buffer.append(character)
                    }
                }
                
                // If the loop completes without chunk.done being true (e.g., stream just ends without a final 'done' marker)
                if !streamDidSignalDone {
                    NSLog("[OllamaService] Stream loop finished without explicit 'done' chunk. Signaling completion with isDone=true.")
                    completion(nil, true, nil) // Ensure 'done' is signaled
                    streamDidSignalDone = true 
                }
                
                NSLog("[OllamaService] StreamChat completed, total chunks: \(chunkCount), total content length: \(totalContent.count)")

            } catch {
                if !streamDidSignalDone {
                    NSLog("[OllamaService] Stream caught error: \(error.localizedDescription). Signaling completion with isDone=true and error.")
                    completion(nil, true, error)
                } else {
                    // Error occurred after stream was already marked done, log it but don't call completion again.
                    NSLog("[OllamaService] Stream caught error: \(error.localizedDescription), but stream already signaled done. Error not sent to completion handler again.")
                }
            }
        }
    }
    
    // MARK: - Model Management API
    
    func getAvailableModels() async throws -> [String] {
        let url = baseURL.appendingPathComponent("tags")
        
        do {
            NSLog("[OllamaService] Fetching models from: \(url)")
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.invalidResponse
            }
            
            NSLog("[OllamaService] HTTP response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                throw OllamaError.httpError(httpResponse.statusCode)
            }
            
            let tagsResponse = try decoder.decode(OllamaTagsResponse.self, from: data)
            NSLog("[OllamaService] Successfully decoded \(tagsResponse.models.count) models")
            return tagsResponse.models.map { $0.name }
            
        } catch let error as DecodingError {
            NSLog("[OllamaService] JSON decoding error: \(error)")
            throw OllamaError.decodingError(error)
        } catch let urlError as URLError {
            NSLog("[OllamaService] URL error: \(urlError)")
            if urlError.code == .cannotConnectToHost {
                throw OllamaError.connectionFailed
            }
            throw OllamaError.networkError(urlError)
        } catch {
            NSLog("[OllamaService] General network error: \(error)")
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
                    NSLog("[OllamaService] Starting pull for model: \(modelName)")
                    
                    let request = PullRequest(name: modelName, stream: true)
                    let requestData = try encoder.encode(request)
                    
                    let pullURL = baseURL.appendingPathComponent("pull")
                    NSLog("[OllamaService] Pull URL: \(pullURL)")
                    
                    var urlRequest = URLRequest(url: pullURL)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = requestData
                    
                    NSLog("[OllamaService] Sending pull request for model: \(modelName)")
                    
                    // Use URLSession.bytes to stream the response
                    let (asyncBytes, response) = try await urlSession.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        NSLog("[OllamaService] Invalid response type for pull request")
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }

                    NSLog("[OllamaService] Pull request HTTP status: \(httpResponse.statusCode)")

                    guard httpResponse.statusCode == 200 else {
                        NSLog("[OllamaService] Pull request failed with status: \(httpResponse.statusCode)")
                        continuation.finish(throwing: OllamaError.httpError(httpResponse.statusCode))
                        return
                    }

                    NSLog("[OllamaService] Pull request successful, starting to process stream")

                    // Process streaming bytes into lines
                    var buffer = ""
                    var lineCount = 0
                    for try await byte in asyncBytes {
                        let char = Character(UnicodeScalar(byte))
                        if char == "\n" {
                            let line = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                            buffer = ""
                            guard !line.isEmpty else { continue }
                            
                            lineCount += 1
                            NSLog("[OllamaService] Processing pull status line \(lineCount): \(line)")
                            
                            do {
                                let status = try decoder.decode(OllamaPullStatus.self, from: Data(line.utf8))
                                NSLog("[OllamaService] Decoded pull status: \(status.status)")
                                if let progress = status.progressPercentage {
                                    NSLog("[OllamaService] Pull progress: \(String(format: "%.1f", progress))%")
                                }
                                continuation.yield(status)
                                
                                if status.status.contains("success") || status.status.contains("complete") {
                                    NSLog("[OllamaService] Pull completed successfully")
                                    continuation.finish()
                                    return
                                }
                            } catch {
                                NSLog("[OllamaService] Failed to decode pull status line: \(line), error: \(error)")
                                // Skip malformed JSON but continue
                                continue
                            }
                        } else {
                            buffer.append(char)
                        }
                    }
                    
                    NSLog("[OllamaService] Pull stream ended, processed \(lineCount) lines")
                    continuation.finish()
                    
                } catch {
                    NSLog("[OllamaService] Pull error for model \(modelName): \(error)")
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
