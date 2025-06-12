# File Description: ChatMessage.swift

**Path:** `Local-AI-Web-Face/Models/ChatMessage.swift`

**Purpose:**

This file defines the data structure for a single chat message within the application. It's a fundamental model used to represent communications between the user and the Ollama LLM.

**Structure:**

*   **`ChatMessage` struct:**
    *   Conforms to `Identifiable` for use in SwiftUI lists.
    *   Conforms to `Codable` for potential future persistence or network transfer (though primarily used locally).
    *   `id: UUID`: A unique identifier for each message.
    *   `sender: Sender`: An enum (`Sender.user` or `Sender.bot`) indicating who sent the message.
    *   `content: String`: The textual content of the message.
    *   `timestamp: Date`: The date and time the message was created.
    *   *(Potential future properties: `isLoading` for bot messages, `messageType` for system messages/errors, `isError`)*
*   **`Sender` enum:**
    *   `case user`: Represents a message from the human user.
    *   `case bot`: Represents a message from the LLM.
    *   Conforms to `String` and `Codable`.

**Key Responsibilities:**

*   To provide a standardized way to represent individual messages in the chat history.
*   To ensure each message can be uniquely identified.
*   To distinguish between messages from the user and the AI.

**How it will be used:**

*   The `ChatViewModel` will manage an array of `ChatMessage` objects to store the conversation history.
*   The `ChatView` will iterate over this array to display each message in the UI.
*   When the user sends a message, a new `ChatMessage` instance (with `sender = .user`) will be created.
*   When the Ollama API returns a response, a new `ChatMessage` instance (with `sender = .bot`) will be created.
