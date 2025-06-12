# Project Roadmap: Ollama Native macOS Client

## Introduction

This document outlines the development roadmap for the Ollama Native macOS Client, a SwiftUI application designed to provide a rich and intuitive interface for interacting with locally run Ollama Large Language Models (LLMs).

## Core Pillars & Vision

The application will be built around three core pillars:

1.  **🚀 Core Chat Interface:** A responsive and intuitive chat window for real-time, streaming interaction with local LLMs.
2.  **📦 Model Management:** Comprehensive tools to list, switch, discover, download, and manage Ollama models.
3.  **🤖 Interactive 2D Avatar:** An animated 2D avatar with Text-to-Speech (TTS) and expressive animations to enhance user engagement.

## Technology Stack

*   **UI Framework:** SwiftUI
*   **Language:** Swift
*   **Architecture:** Model-View-ViewModel (MVVM)
*   **Animation (Avatar):** SpriteKit (or potentially Live2D Cubism SDK if feasible)
*   **Audio (TTS):** AVFoundation (AVSpeechSynthesizer)
*   **Local LLM Interaction:** HTTP requests to the local Ollama API (e.g., `http://localhost:11434/api/chat`).

## Development Phases

### Phase 1: Foundational Chat & Basic Model Management (MVP)

*   **Objective:** Establish a functional chat interface and basic model selection.
*   **Key Features:**
    *   **Environment Setup:**
        *   Instructions for installing Ollama.
    *   **Chat View (`ChatView.swift`):**
        *   `TextField` for user input.
        *   Send button.
        *   Scrollable display area for conversation history (user prompts and LLM responses).
        *   Real-time streaming of LLM responses.
    *   **Ollama Service (`OllamaService.swift`):**
        *   Function to send chat requests to `http://localhost:11434/api/chat`.
        *   Handle JSON parsing for requests and responses.
        *   Basic error handling for API communication.
        *   Loading state indicators in the UI.
    *   **Model Management (`ModelManager.swift` & `SettingsView.swift` - Basic):**
        *   Function to list available local models (e.g., by calling `ollama ps` or `/api/tags`).
        *   Simple UI element (e.g., `Picker` or `Menu`) in `SettingsView` to display and select the active model.
        *   Persist the selected model using `UserDefaults` or AppStorage.
    *   **Data Models (`ChatMessage.swift`):**
        *   Struct to represent a chat message (sender, content, timestamp, etc.).
*   **Timeline:** Weeks 1-3

### Phase 2: Enhanced Model Management & UI Polish

*   **Objective:** Full model management capabilities and improved user experience.
*   **Key Features:**
    *   **Advanced Model Management (`ModelManager.swift`, `SettingsView.swift`):**
        *   Switch active model (e.g., `ollama run <model>`).
        *   Potentially stop models (`ollama stop <model>`) if API endpoints are available or via shell commands.
        *   UI for browsing and pulling new models from the Ollama library (requires exploring `/api/pull`).
        *   Display model details (size, family, last updated).
        *   Deleting local models.
    *   **UI/UX Refinements:**
        *   Improved chat interface aesthetics.
        *   Clearer loading and error states.
        *   Application settings (e.g., theme, font size).
    *   **Error Handling:**
        *   More robust error handling and user feedback across the application.
*   **Timeline:** Weeks 4-5

### Phase 3: Interactive Avatar & Text-to-Speech (TTS)

*   **Objective:** Introduce an engaging avatar with voice output.
*   **Key Features:**
    *   **Text-to-Speech (`TTSManager.swift`, `ChatView.swift`):**
        *   Integrate `AVSpeechSynthesizer` to voice LLM responses.
        *   Allow users to select voice and speech rate.
        *   Option to enable/disable TTS.
    *   **Avatar View (`AvatarView.swift`):**
        *   Basic 2D avatar display (placeholder or simple animation).
        *   Integrate with SpriteKit for animations.
    *   **Avatar Animation (Initial):**
        *   Idle animation.
        *   Simple speaking animation triggered by TTS.
    *   **(Optional Stretch Goal) Advanced Avatar Features:**
        *   Lip synchronization (could be complex, investigate simplified approaches or Live2D).
        *   Contextual expressions (e.g., thinking, responding).
        *   Face tracking via ARKit (highly ambitious, for later consideration).
*   **Timeline:** Weeks 6-8+

### Phase 4: Refinement, Testing, and Packaging

*   **Objective:** Polish the application, conduct thorough testing, and prepare for distribution.
*   **Key Features:**
    *   **Performance Optimization:**
        *   Optimize model loading and chat responsiveness.
        *   Reduce resource consumption.
    *   **Accessibility (A11y):**
        *   Ensure the app is usable with VoiceOver and other accessibility features.
    *   **Testing:**
        *   Unit tests for services and view models.
        *   UI tests for critical user flows.
    *   **Documentation:**
        *   Update README with detailed usage instructions.
        *   Create `CONTRIBUTING.md`.
    *   **App Packaging:**
        *   Icon design.
        *   Build and archive for distribution (e.g., .app bundle).
*   **Timeline:** Ongoing throughout development, with a dedicated focus in Weeks 9-10.

## Project Structure (High-Level)

*   **`Local-AI-Web-Face/`** (Main Application Code)
    *   **`Models/`**: `ChatMessage.swift`, etc.
    *   **`Views/`**: `ChatView.swift`, `SettingsView.swift`, `AvatarView.swift`
    *   **`ViewModels/`**: `ChatViewModel.swift`, `SettingsViewModel.swift` (following MVVM)
    *   **`Services/`**: `OllamaService.swift`, `ModelManager.swift`, `TTSManager.swift`
    *   **`Extensions/`**: Utility extensions.
    *   **`Assets.xcassets/`**: App icons, colors, images.
    *   `Local_AI_Web_FaceApp.swift` (App entry point)
    *   `ContentView.swift` (Main view hosting other views)
*   **`Local-AI-Web-Face.xcodeproj/`**: Xcode project files.
*   **`Local-AI-Web-FaceTests/`**: Unit tests.
*   **`Local-AI-Web-FaceUITests/`**: UI tests.
*   **`Descriptions/`**: Markdown descriptions for each major Swift file.
*   **`Roadmap/`**: This file.
*   **`Blueprints/`**: Original planning documents.

## Next Steps (Immediate)

1.  **Set up the project structure** within `Local-AI-Web-Face/` as outlined above.
2.  **Create placeholder Swift files** for all planned components.
3.  **Write initial descriptions** for each Swift file in the `Descriptions/` folder.
4.  **Begin implementation of Phase 1**, starting with the `OllamaService.swift` and basic `ChatView.swift`.

This roadmap will be a living document and may be updated as the project progresses and new insights are gained.
