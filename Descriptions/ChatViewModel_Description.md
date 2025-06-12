# File Description: ChatViewModel.swift

**Path:** `Local-AI-Web-Face/ViewModels/ChatViewModel.swift`

**Purpose:**

This file defines the `ChatViewModel`, which acts as the intermediary between the `ChatView` (UI) and the underlying services (`OllamaService`, `ModelManager`). It manages the state of the chat interface, handles user interactions, and processes data for display.

**Structure (`ChatViewModel` class):**

*   Conforms to `ObservableObject` to allow SwiftUI views to subscribe to its changes.
*   **Published Properties:**
    *   `@Published var messages: [ChatMessage] = []`: An array to hold all chat messages in the current session.
    *   `@Published var inputText: String = ""`: The current text entered by the user in the input field.
    *   `@Published var isLoading: Bool = false`: A boolean to indicate if the app is currently waiting for a response from the LLM.
    *   `@Published var currentModelName: String = ""`: The name of the currently selected Ollama model.
    *   `@Published var errorMessage: String? = nil`: An optional string to display error messages to the user.
*   **Dependencies (Services):**
    *   `ollamaService: OllamaService` (instance)
    *   `modelManager: ModelManager` (instance, likely observed or passed in)
*   **Private Properties:**
    *   `cancellables = Set<AnyCancellable>()`: For managing Combine subscriptions.

**Key Responsibilities & Functions:**

*   **`sendMessage()`:**
    *   Takes the `inputText` from the user.
    *   Creates a `ChatMessage` with `sender = .user` and adds it to the `messages` array.
    *   Clears `inputText`.
    *   Sets `isLoading = true`.
    *   Calls the appropriate method in `OllamaService` to send the message to the Ollama API, using the `currentModelName`.
    *   Handles the streaming response from `OllamaService`:
        *   Appends incoming chunks to a new `ChatMessage` (or updates an existing one) with `sender = .bot`.
        *   Sets `isLoading = false` when the stream completes or an error occurs.
    *   Handles API errors and updates `errorMessage`.
*   **`loadInitialMessages()` / `clearChat()`:**
    *   Functions to manage the chat history (e.g., load from persistence if implemented, or clear the current session).
*   **`observeModelChanges()`:**
    *   Subscribes to changes in the `ModelManager` to update `currentModelName` when the user selects a different model in `SettingsView`.
*   **Error Handling:**
    *   Provides mechanisms to display errors to the user via `errorMessage`.

**How it will be used:**

*   The `ChatView` will create an instance of `ChatViewModel` (likely as a `@StateObject` or `@ObservedObject`).
*   UI elements in `ChatView` will bind to the published properties of `ChatViewModel` (e.g., `TextField` to `inputText`, `List` to `messages`).
*   Actions in `ChatView` (e.g., tapping the send button) will call functions on the `ChatViewModel` (e.g., `sendMessage()`).
