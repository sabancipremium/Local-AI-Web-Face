# File Description: OllamaService.swift

**Path:** `Local-AI-Web-Face/Services/OllamaService.swift`

**Purpose:**

This file defines the `OllamaService` class, which is responsible for all direct communication with the local Ollama API. It abstracts the network request details, JSON parsing, and error handling related to Ollama interactions.

**Structure (`OllamaService` class):**

*   **Properties:**
    *   `baseURL: URL = URL(string: "http://localhost:11434/api")!`: The base URL for the Ollama API.
    *   `urlSession: URLSession = .shared`: An instance of `URLSession` for making network requests.

**Key Responsibilities & Functions:**

*   **`sendChatMessage(prompt: String, model: String, stream: Bool = true, history: [ChatMessage] = []) async throws -> AsyncThrowingStream<String, Error>` (for streaming):**
    *   Constructs the request body for the `/api/chat` endpoint, including the user's prompt, selected model, and optionally, conversation history for context.
    *   Makes an HTTP POST request to `baseURL.appendingPathComponent("chat")`.
    *   Handles the streaming response if `stream` is true:
        *   The Ollama API for chat with streaming returns a series of JSON objects on a single connection, each representing a chunk of the response.
        *   This function will need to parse these individual JSON objects from the stream.
        *   Each JSON object typically has a `message.content` field (for ongoing responses) or a `done` field.
        *   It will yield the `message.content` string for each chunk through the `AsyncThrowingStream`.
    *   If `stream` is false, it would fetch the full response and parse it (less common for chat).
    *   Handles network errors, HTTP status code errors, and JSON parsing errors.
*   **`getAvailableModels() async throws -> [OllamaTag]` (or a simpler string array):**
    *   Makes an HTTP GET request to `baseURL.appendingPathComponent("tags")` (or `/api/ps` if using that for more detail).
    *   Parses the JSON response which contains a list of locally available models.
    *   The response typically includes model names, sizes, modification times, etc. A struct like `OllamaTag` would be defined to decode this.
    *   Returns an array of model information (e.g., `[OllamaTag]` or just `[String]` for names).
    *   Handles errors.
*   **`pullModel(modelName: String, stream: Bool = true) async throws -> AsyncThrowingStream<OllamaPullStatus, Error>` (for streaming progress):**
    *   Constructs the request body for the `/api/pull` endpoint.
    *   Makes an HTTP POST request.
    *   Handles the streaming response which provides status updates on the download (e.g., "pulling manifest", progress percentage).
    *   A struct like `OllamaPullStatus` would be defined to decode these status messages.
    *   Yields `OllamaPullStatus` objects through the stream.
    *   Handles errors.
*   **`deleteModel(modelName: String) async throws -> Void`:**
    *   Constructs the request body for the `/api/delete` endpoint.
    *   Makes an HTTP DELETE request.
    *   Handles success/failure response.
*   **Helper methods for request construction and response parsing.**

**Data Structures (likely defined within or alongside this service):**

*   `ChatRequest`: Struct for encoding the `/api/chat` request body.
*   `ChatResponseChunk`: Struct for decoding individual chunks from the streaming chat response.
*   `OllamaTag`: Struct for decoding model information from `/api/tags`.
*   `PullRequest`: Struct for encoding the `/api/pull` request body.
*   `OllamaPullStatus`: Struct for decoding status messages from the `/api/pull` stream.

**How it will be used:**

*   The `ChatViewModel` will use `sendChatMessage()` to interact with the LLM.
*   The `ModelManager` (or `SettingsViewModel` via `ModelManager`) will use `getAvailableModels()`, `pullModel()`, and `deleteModel()` to manage Ollama models.
*   This service centralizes Ollama API logic, making ViewModels cleaner and testing easier.
