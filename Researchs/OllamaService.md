The Ollama API allows your application to communicate with a running Ollama instance, typically on `http://localhost:11434`.[1, 2] This interaction happens over HTTP, using JSON for requests and responses.

### Key Ollama API Endpoints and Their Usage:

Here's a breakdown of the primary API endpoints you'll be using:

1.  **Generate a Completion (`/api/generate`)** [2, 3, 4]
    *   **Purpose:** Used for single-turn interactions where you provide a prompt and expect a direct completion.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `model`: (Required) The name of the model to use (e.g., "llama3.2").[2]
        *   `prompt`: (Required) The text prompt for the model.[2]
        *   `stream`: (Optional) Boolean. If `true`, the response is streamed back in chunks. If `false` (default), the full response is sent once generation is complete.[2, 3] Streaming is highly recommended for a responsive UI.
        *   `images`: (Optional) An array of base64-encoded strings representing images, for multimodal models.[2]
        *   `format`: (Optional) Set to `"json"` to instruct the model to return a JSON object. You might need to guide the model in the prompt to produce valid JSON.[2, 3]
        *   `options`: (Optional) An object to specify additional model parameters like `temperature`, `seed` (for reproducible outputs), etc..[2]
        *   `suffix`: (Optional) Text to append after the model's response.[2]
        *   `keep_alive`: (Optional) Controls how long the model stays loaded in memory after the request (e.g., "5m").[2]
    *   **Response (Streaming):** A series of JSON objects. Each object typically contains:
        *   `model`: The model name.
        *   `created_at`: Timestamp.
        *   `response`: A chunk of the generated text.
        *   `done`: Boolean, `false` until the final chunk.
        The final chunk will have `done: true` and may include additional fields like `context` (an array of token IDs representing the conversation history), `total_duration`, `prompt_eval_count`, `eval_count`, etc..[2, 5]
    *   **Response (Non-Streaming):** A single JSON object containing the full `response` and other metadata as in the final streaming chunk.[2, 5]

2.  **Generate a Chat Completion (`/api/chat`)** [2, 4, 6]
    *   **Purpose:** Designed for conversational interactions, maintaining context across multiple turns.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `model`: (Required) The model name.[2]
        *   `messages`: (Required) An array of message objects. Each message object has:
            *   `role`: String - "system", "user", or "assistant".[2]
            *   `content`: String - The text of the message.[2]
            *   `images`: (Optional) An array of base64-encoded image strings.[2]
        *   `stream`: (Optional) Boolean, same as in `/api/generate`.[2, 4]
        *   `format`: (Optional) Set to `"json"` for structured JSON output.[2]
        *   `options`: (Optional) Additional model parameters.[2]
        *   `tools`: (Optional) An array of tool definitions the model can choose to use. This is for more advanced function-calling capabilities.[2, 6]
        *   `keep_alive`: (Optional) Controls how long the model stays loaded.[2]
    *   **Response (Streaming):** A series of JSON objects. Each object typically contains:
        *   `model`: The model name.
        *   `created_at`: Timestamp.
        *   `message`: An object with `role` ("assistant") and `content` (a chunk of the response).
        *   `done`: Boolean, `false` until the final chunk.
        The final chunk will have `done: true` and may include `total_duration`, `prompt_eval_count`, `eval_count`, etc. If tools are used, `message` might contain `tool_calls`.[2, 6, 7]
    *   **Response (Non-Streaming):** A single JSON object with the complete assistant message and metadata.[2]

3.  **List Local Models (`/api/tags`)** [3, 4, 8]
    *   **Purpose:** Retrieves a list of all models currently downloaded and available locally.
    *   **Method:** `GET`
    *   **Response (JSON):** An object containing a `models` array. Each element in the array is an object with details like:
        *   `name`: The model name (e.g., "llama3.2:latest").
        *   `model`: The full model identifier.
        *   `modified_at`: Timestamp.
        *   `size`: Size in bytes.
        *   `digest`: A unique identifier for the model version.
        *   `details`: An object with more info like `format`, `family`, `parameter_size`, `quantization_level`.[4]

4.  **Pull a Model (`/api/pull`)** [3, 8]
    *   **Purpose:** Downloads a model from the Ollama library.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `name`: (Required) The name of the model to pull (e.g., "llama3.2").[3, 8]
        *   `stream`: (Optional) Boolean. If `true`, the API streams status updates about the download progress.
    *   **Response (Streaming):** A series of JSON objects indicating the download status (e.g., "pulling manifest", "downloading part...", "verifying sha256", "success"). This is crucial for providing feedback to the user.
        *   Each status object might contain `status`, `digest`, `total`, and `completed` fields to show progress.

5.  **Show Model Information (`/api/show`)** [2, 8]
    *   **Purpose:** Fetches detailed information about a specific locally available model.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `name`: (Required) The name of the model (e.g., "llama3.2").[8]
    *   **Response (JSON):** An object containing details like `modelfile` content, `parameters`, `template`, `details` (family, format, etc.), and `license`.

6.  **Delete a Model (`/api/delete`)** [2, 3, 8]
    *   **Purpose:** Removes a model from local storage.
    *   **Method:** `DELETE`
    *   **Request Body (JSON):**
        *   `name` (or `model` in some docs): (Required) The name of the model to delete.[3, 8]
    *   **Response:** Typically a 200 OK status on success.

7.  **Copy a Model (`/api/copy`)** [2, 3, 8]
    *   **Purpose:** Creates a copy of an existing local model under a new name.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `source`: (Required) The name of the existing model to copy.[3, 8]
        *   `destination`: (Required) The new name for the copied model.[3, 8]
    *   **Response:** Typically a 200 OK status on success.

8.  **Create a Model (`/api/create`)** [2, 8]
    *   **Purpose:** Creates a new model from a Modelfile.
    *   **Method:** `POST`
    *   **Request Body (JSON):**
        *   `name`: (Required) The name for the new model being created.[8]
        *   `modelfile`: (Required) The content of the Modelfile as a string.[8]
        *   `stream`: (Optional) Boolean. If `true`, streams status updates during model creation.
    *   **Response (Streaming):** A series of JSON objects indicating the creation status.

### Structuring an `OllamaService` in Swift

An `OllamaService` class in your Swift application would encapsulate all interactions with these API endpoints. It would handle constructing requests, sending them, parsing responses (including handling streams), and managing errors.

Here's a conceptual outline:

```swift
import Foundation

// Base URL for the Ollama API
let OLLAMA_BASE_URL = URL(string: "http://localhost:11434/api")!

// MARK: - Codable Structs for API Requests and Responses

struct GenerateRequest: Codable {
    let model: String
    let prompt: String
    var images:? = nil // Base64 encoded images
    var stream: Bool = true
    var format: String? = nil // "json"
    var options:? = nil // For temperature, seed etc.
    // Add other parameters like suffix, keep_alive as needed
}

// For streaming responses from /api/generate
struct GenerateResponseChunk: Codable, Identifiable {
    let id = UUID() // For SwiftUI lists if needed
    let model: String
    let createdAt: String // Consider DateFormatter for actual Date
    let response: String
    let done: Bool
    // Optional fields in the final chunk
    let context: [Int]?
    let totalDuration: Int?
    let loadDuration: Int?
    let promptEvalCount: Int?
    let promptEvalDuration: Int?
    let evalCount: Int?
    let evalDuration: Int?
    // Add done_reason if needed
}

struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    let role: String // "system", "user", "assistant"
    var content: String
    var images:? = nil // Base64 encoded images
    // Add tool_calls if implementing tool use
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    var stream: Bool = true
    var format: String? = nil // "json"
    var options:? = nil
    // Add tools, keep_alive as needed
}

// For streaming responses from /api/chat
struct ChatResponseChunk: Codable, Identifiable {
    let id = UUID() // For SwiftUI lists
    let model: String
    let createdAt: String
    struct MessageContent: Codable {
        let role: String
        var content: String
        // Add tool_calls if needed
    }
    let message: MessageContent? // Optional because the last chunk might only have 'done'
    let done: Bool
    // Optional fields in the final chunk
    let totalDuration: Int?
    //... other timing/context fields similar to GenerateResponseChunk
}

struct LocalModel: Codable, Identifiable {
    let id = UUID() // Or use 'digest' if it's guaranteed unique and stable
    let name: String
    let model: String
    let modifiedAt: String
    let size: Int64
    let digest: String
    struct Details: Codable {
        let parentModel: String?
        let format: String?
        let family: String?
        let families:?
        let parameterSize: String?
        let quantizationLevel: String?
    }
    let details: Details
}

struct ListModelsResponse: Codable {
    let models: [LocalModel]
}

struct PullModelRequest: Codable {
    let name: String
    var stream: Bool = true
}

struct PullStatusChunk: Codable {
    let status: String
    let digest: String?
    let total: Int64?
    let completed: Int64?
}

struct ShowModelRequest: Codable {
    let name: String
}

struct ModelInfoResponse: Codable {
    let license: String?
    let modelfile: String?
    let parameters: String? // This often contains new-line separated key-value pairs
    let template: String?
    struct Details: Codable { // Same as LocalModel.Details
        let parentModel: String?
        let format: String?
        let family: String?
        let families:?
        let parameterSize: String?
        let quantizationLevel: String?
    }
    let details: Details
    // Add other fields like project_url, system_prompt etc. if needed
}

struct DeleteModelRequest: Codable {
    let name: String // Ollama docs sometimes use 'model', sometimes 'name'. 'name' is more common in API clients.
}

struct CopyModelRequest: Codable {
    let source: String
    let destination: String
}

struct CreateModelRequest: Codable {
    let name: String
    let modelfile: String
    var stream: Bool = true
}

struct CreateStatusChunk: Codable {
    let status: String
}


// Helper for in Codable structs
struct AnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value?? ()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } // Add other types as needed
        // For dictionaries or arrays, you might need a more complex AnyCodable implementation
        // or ensure your 'options' are always of a consistent structure.
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}


// MARK: - OllamaService Class

enum OllamaError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
}

class OllamaService {
    private let baseURL: URL
    private let urlSession: URLSession

    init(baseURL: URL = OLLAMA_BASE_URL, urlSession: URLSession =.shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    private func buildRequest(for endpoint: String, method: String = "POST", body: (some Encodable)? = nil) throws -> URLRequest {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw OllamaError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    // Example: Generate (Streaming)
    func generate(requestPayload: GenerateRequest) -> AsyncThrowingStream<GenerateResponseChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(for: "generate", body: requestPayload)
                    let (bytes, response) = try await urlSession.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        // Attempt to read error message from body
                        var errorMessage = ""
                        for try await byte in bytes { // Assuming error body is small and UTF-8
                            errorMessage += String(decoding: [byte], as: UTF8.self)
                        }
                        continuation.finish(throwing: OllamaError.serverError(statusCode: httpResponse.statusCode, message: errorMessage.isEmpty? nil : errorMessage))
                        return
                    }
                    
                    var accumulatedData = Data()
                    for try await byte in bytes {
                        accumulatedData.append(byte)
                        // Ollama streams NDJSON (newline-delimited JSON)
                        // So, we look for newlines to parse individual JSON objects
                        while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                            let jsonData = accumulatedData.subdata(in: 0..<newlineIndex)
                            accumulatedData.removeSubrange(0...newlineIndex)
                            if!jsonData.isEmpty { // Avoid decoding empty data
                                do {
                                    let chunk = try JSONDecoder().decode(GenerateResponseChunk.self, from: jsonData)
                                    continuation.yield(chunk)
                                    if chunk.done {
                                        continuation.finish()
                                        return
                                    }
                                } catch {
                                    // Handle potential partial JSON or other decoding errors
                                    // This part can be tricky with streaming; robust error handling is key
                                    print("Decoding error for chunk: \(error)")
                                    // Decide whether to throw or try to recover/skip
                                }
                            }
                        }
                    }
                    // If loop finishes and stream wasn't closed by a 'done: true' chunk,
                    // it might indicate an incomplete stream or final non-newline-terminated chunk.
                    if!accumulatedData.isEmpty {
                         do {
                            let chunk = try JSONDecoder().decode(GenerateResponseChunk.self, from: accumulatedData)
                            continuation.yield(chunk)
                            if chunk.done {
                                continuation.finish()
                                return
                            }
                        } catch {
                             print("Decoding error for final accumulated data: \(error)")
                        }
                    }
                    continuation.finish() // Or throw if an error occurred that wasn't handled

                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // Example: Chat (Streaming) - Similar structure to generate
    func chat(requestPayload: ChatRequest) -> AsyncThrowingStream<ChatResponseChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(for: "chat", body: requestPayload)
                    let (bytes, response) = try await urlSession.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        var errorMessage = ""
                        for try await byte in bytes {
                            errorMessage += String(decoding: [byte], as: UTF8.self)
                        }
                        continuation.finish(throwing: OllamaError.serverError(statusCode: httpResponse.statusCode, message: errorMessage.isEmpty? nil : errorMessage))
                        return
                    }

                    var accumulatedData = Data()
                    for try await byte in bytes {
                        accumulatedData.append(byte)
                        while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                            let jsonData = accumulatedData.subdata(in: 0..<newlineIndex)
                            accumulatedData.removeSubrange(0...newlineIndex)
                             if!jsonData.isEmpty {
                                do {
                                    let chunk = try JSONDecoder().decode(ChatResponseChunk.self, from: jsonData)
                                    continuation.yield(chunk)
                                    if chunk.done {
                                        continuation.finish()
                                        return
                                    }
                                } catch {
                                     print("Chat decoding error for chunk: \(error)")
                                }
                            }
                        }
                    }
                     if!accumulatedData.isEmpty {
                         do {
                            let chunk = try JSONDecoder().decode(ChatResponseChunk.self, from: accumulatedData)
                            continuation.yield(chunk)
                            if chunk.done {
                                continuation.finish()
                                return
                            }
                        } catch {
                             print("Chat decoding error for final accumulated data: \(error)")
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // Example: List Local Models
    func listLocalModels() async throws -> [LocalModel] {
        let request = try buildRequest(for: "tags", method: "GET")
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw OllamaError.invalidResponse // Or more specific error based on status code
        }
        do {
            let decodedResponse = try JSONDecoder().decode(ListModelsResponse.self, from: data)
            return decodedResponse.models
        } catch {
            throw OllamaError.decodingError(error)
        }
    }

    // Example: Pull Model (Streaming)
    func pullModel(modelName: String) -> AsyncThrowingStream<PullStatusChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let requestPayload = PullModelRequest(name: modelName, stream: true)
                    let request = try buildRequest(for: "pull", body: requestPayload)
                    let (bytes, response) = try await urlSession.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        continuation.finish(throwing: OllamaError.invalidResponse)
                        return
                    }
                    
                    var accumulatedData = Data()
                    for try await byte in bytes {
                        accumulatedData.append(byte)
                        while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                            let jsonData = accumulatedData.subdata(in: 0..<newlineIndex)
                            accumulatedData.removeSubrange(0...newlineIndex)
                            if!jsonData.isEmpty {
                                do {
                                    let chunk = try JSONDecoder().decode(PullStatusChunk.self, from: jsonData)
                                    continuation.yield(chunk)
                                    // The "success" status often comes as the very last message for pull
                                    if chunk.status.lowercased() == "success" {
                                        continuation.finish()
                                        return
                                    }
                                } catch {
                                     print("Pull model decoding error for chunk: \(error)")
                                }
                            }
                        }
                    }
                    if!accumulatedData.isEmpty {
                         do {
                            let chunk = try JSONDecoder().decode(PullStatusChunk.self, from: accumulatedData)
                            continuation.yield(chunk)
                            if chunk.status.lowercased() == "success" {
                                continuation.finish()
                                return
                            }
                        } catch {
                             print("Pull model decoding error for final accumulated data: \(error)")
                        }
                    }
                    continuation.finish() // Finish if stream ends without explicit success, or handle as error
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // Example: Show Model Info
    func showModelInfo(modelName: String) async throws -> ModelInfoResponse {
        let requestPayload = ShowModelRequest(name: modelName)
        let request = try buildRequest(for: "show", body: requestPayload)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // You might want to try decoding an error message from 'data' here
            throw OllamaError.invalidResponse
        }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy =.convertFromSnakeCase // If API uses snake_case
            return try decoder.decode(ModelInfoResponse.self, from: data)
        } catch {
            throw OllamaError.decodingError(error)
        }
    }

    // Example: Delete Model
    func deleteModel(modelName: String) async throws {
        let requestPayload = DeleteModelRequest(name: modelName)
        let request = try buildRequest(for: "delete", method: "DELETE", body: requestPayload)
        let (_, response) = try await urlSession.data(for: request) // We don't need the data for a successful delete

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            // Consider checking for 404 if model not found vs other errors
            throw OllamaError.invalidResponse // Or a more specific error
        }
        // If status code is OK, the operation was successful.
    }
    
    // Implement other methods (copyModel, createModel, etc.) similarly,
    // paying attention to whether they stream responses or return a single object.
}

```

**Key Considerations for `OllamaService`:**

*   **Error Handling:** Robust error handling is critical. This includes network errors, HTTP status code errors (like 404 if a model isn't found, 500 for server issues), and JSON decoding errors.[9] The example above includes a basic `OllamaError` enum and checks HTTP status codes.
*   **Streaming NDJSON:** Ollama streams responses as newline-delimited JSON (NDJSON). Your parsing logic needs to handle accumulating bytes and decoding each JSON object as it's fully received (i.e., after a newline character).[5] The example `generate` and `chat` methods attempt this.
*   **Swift Concurrency (`async/await`, `AsyncThrowingStream`):** Modern Swift concurrency makes handling these asynchronous operations much cleaner.[10] `AsyncThrowingStream` is ideal for representing streamed responses.
*   **Codable Structs:** Define `Codable` Swift structs for all request and response bodies to ensure type safety and easy JSON encoding/decoding.[11, 12]
*   **Dependency Injection:** Your SwiftUI Views (or ViewModels) would typically receive an instance of `OllamaService` through dependency injection.[13, 14]
*   **Client Configuration:** Allow configuring the `baseURL` if Ollama isn't running on the default localhost address.[15]
*   **Testing:** Design the service to be testable, perhaps by injecting a mock `URLSession` or by defining a protocol that `OllamaService` conforms to, allowing for mock implementations in tests.

This structure provides a solid foundation. Projects like Swollama on GitHub offer more complete Swift client implementations for Ollama that you can also reference for advanced features and more robust error handling.[10] The official Ollama Python and JavaScript libraries also serve as good examples of how to interact with the API.[6, 9]