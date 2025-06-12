# File Description: Local_AI_Web_FaceApp.swift

**Path:** `Local-AI-Web-Face/Local-AI-Web-Face/Local_AI_Web_FaceApp.swift`

**Purpose:**

This is the main entry point for the SwiftUI application. It defines the app structure, initializes shared services or managers, and sets up the initial view hierarchy.

**Structure:**

```swift
import SwiftUI

@main
struct Local_AI_Web_FaceApp: App {
    // StateObject or EnvironmentObject for shared services/managers
    @StateObject private var modelManager: ModelManager
    @StateObject private var ttsManager: TTSManager
    @StateObject private var ollamaService: OllamaService
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var chatViewModel: ChatViewModel

    init() {
        // Initialize services first
        let ollamaService = OllamaService()
        let modelManager = ModelManager(ollamaService: ollamaService)
        let ttsManager = TTSManager()

        // Initialize ViewModels with their dependencies
        let settingsViewModel = SettingsViewModel(modelManager: modelManager, ttsManager: ttsManager)
        let chatViewModel = ChatViewModel(ollamaService: ollamaService, modelManager: modelManager, ttsManager: ttsManager)
        
        // Assign to StateObjects
        _ollamaService = StateObject(wrappedValue: ollamaService)
        _modelManager = StateObject(wrappedValue: modelManager)
        _ttsManager = StateObject(wrappedValue: ttsManager)
        _settingsViewModel = StateObject(wrappedValue: settingsViewModel)
        _chatViewModel = StateObject(wrappedValue: chatViewModel)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelManager)
                .environmentObject(ttsManager)
                .environmentObject(settingsViewModel)
                .environmentObject(chatViewModel)
                // OllamaService is often not directly an EnvironmentObject unless views need direct access beyond ViewModels
        }
        // Potentially add a Settings scene for macOS
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(modelManager)
                .environmentObject(ttsManager)
                .environmentObject(settingsViewModel)
        }
        #endif
    }
}
```

**Key Responsibilities:**

*   **`@main` Attribute:** Marks this struct as the entry point of the application.
*   **App Protocol Conformance:** Implements the `App` protocol, requiring a `body` property that returns one or more `Scene`s.
*   **Service Initialization:**
    *   Creates instances of shared services like `OllamaService`, `ModelManager`, and `TTSManager`.
    *   These are typically initialized as `@StateObject` here to ensure their lifecycle is managed by the app.
*   **ViewModel Initialization:**
    *   Creates instances of primary ViewModels like `ChatViewModel` and `SettingsViewModel`, injecting their dependencies (the services created above).
*   **Environment Objects:**
    *   Injects the shared services and ViewModels into the SwiftUI environment using the `.environmentObject()` modifier on the root view (`ContentView`). This makes them accessible to any child view in the hierarchy.
*   **Scene Definition (`WindowGroup`, `Settings`):**
    *   `WindowGroup`: Defines the main window scene for the application, displaying `ContentView`.
    *   `Settings` (macOS): Defines a standard settings scene, often used to display a dedicated `SettingsView`.

**How it will be used:**

*   This file is automatically run when the application starts.
*   It sets up the foundational objects and view structure for the entire app.
*   `ContentView` will be the first view displayed and will have access to the shared objects via `@EnvironmentObject`.

**Dependencies:**

*   `ContentView.swift`: The root view of the application.
*   All Service files (`OllamaService.swift`, `ModelManager.swift`, `TTSManager.swift`).
*   All ViewModel files (`ChatViewModel.swift`, `SettingsViewModel.swift`).

This setup ensures that critical services and view models are initialized once and shared throughout the application, following best practices for SwiftUI architecture.
