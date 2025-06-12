# File Description: ChatView.swift

**Path:** `Local-AI-Web-Face/Views/ChatView.swift`

**Purpose:**

This file defines the `ChatView`, which is the primary user interface for interacting with the Ollama LLM. It displays the conversation history, provides an input field for the user to type messages, and a button to send them.

**Structure (`ChatView` struct):**

*   Conforms to `View`.
*   **State Management:**
    *   `@StateObject private var viewModel: ChatViewModel`: Owns and manages the lifecycle of the `ChatViewModel`. (Alternatively, could be `@ObservedObject` if the ViewModel is created and passed in from a parent view like `ContentView`).
*   **Body Layout (Conceptual):**
    *   `VStack` (main container):
        *   **Message Display Area:**
            *   `ScrollViewReader` wrapping a `ScrollView` to allow automatic scrolling to the latest message.
            *   `LazyVStack` (or `List`) to iterate over `viewModel.messages`.
                *   For each `ChatMessage` in `viewModel.messages`:
                    *   Display a `MessageRowView` (a subview, potentially defined in the same file or separately).
                    *   `MessageRowView` would differentiate between user and bot messages (e.g., alignment, background color).
                    *   Apply `.id(message.id)` for `ScrollViewReader`.
        *   **Loading Indicator:**
            *   `if viewModel.isLoading`: Display a `ProgressView` or custom loading animation.
        *   **Error Display:**
            *   `if let errorMessage = viewModel.errorMessage`: Display the error message (e.g., in a `Text` view with a distinct style).
        *   **Input Area (`HStack`):**
            *   `TextField("Type a message...", text: $viewModel.inputText)`: Bound to the ViewModel's `inputText`.
                *   Potentially with `.onSubmit(viewModel.sendMessage)` for sending via Return key.
            *   `Button(action: viewModel.sendMessage)`:
                *   Label: "Send" or an icon (e.g., `Image(systemName: "paperplane.fill")`).
                *   `.disabled(viewModel.inputText.isEmpty || viewModel.isLoading)`: Disable when input is empty or a message is already being processed.

**Key UI Elements & Interactions:**

*   **Message List:** Displays `ChatMessage` objects. Should scroll automatically as new messages are added.
*   **Text Input:** Allows users to type their messages. Bound to `viewModel.inputText`.
*   **Send Button:** Triggers `viewModel.sendMessage()`.
*   **Visual Feedback:** Shows loading states and error messages from the `viewModel`.

**Sub-Views (Potential):**

*   **`MessageRowView(message: ChatMessage)` struct:**
    *   Displays a single chat message.
    *   Uses an `HStack` to align message content (e.g., leading for bot, trailing for user).
    *   Applies different styling (background, text color) based on `message.sender`.
    *   May include a timestamp or sender icon.

**How it will be used:**

*   This view will be a central part of the `ContentView` or the main app navigation.
*   It relies entirely on the `ChatViewModel` for its data and actions.
*   It focuses solely on presentation and user input, delegating all logic to the ViewModel.

**Initial Implementation Notes (from placeholder):**

```swift
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel() // Assuming ChatViewModel is appropriately initialized with its dependencies

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            // MessageRowView(message: message)
                            // Placeholder for MessageRowView:
                            HStack {
                                if message.sender == .user {
                                    Spacer()
                                    Text(message.content)
                                        .padding(10)
                                        .background(Color.blue.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.content)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                    Spacer()
                                }
                            }
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                // Add .onChange(of: viewModel.messages.count) { _ in proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom) } for auto-scroll
            }

            if viewModel.isLoading {
                ProgressView("Thinking...")
                    .padding()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            HStack {
                TextField("Enter message to Ollama...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                Button {
                    viewModel.sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding()
        }
        .onAppear {
            // viewModel.loadInitialData() or similar if needed
        }
    }
}
```
This provides a more concrete starting point for the actual implementation based on the description.
