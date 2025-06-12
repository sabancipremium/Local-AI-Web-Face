# File Description: SettingsView.swift

**Path:** `Local-AI-Web-Face/Views/SettingsView.swift`

**Purpose:**

This file defines the `SettingsView`, a SwiftUI view that allows users to configure various application settings. Initially, this will focus on Ollama model management (selecting the active model, viewing available models, potentially downloading/deleting models) and later expand to include Text-to-Speech (TTS) preferences.

**Structure (`SettingsView` struct):**

*   Conforms to `View`.
*   **State Management:**
    *   `@StateObject private var viewModel: SettingsViewModel`: Owns and manages the lifecycle of the `SettingsViewModel`. (Could also be `@ObservedObject` if injected, depending on how `ModelManager` and `TTSManager` are provided to it).
*   **Body Layout (Conceptual - using `Form` for typical settings layout):**
    *   `NavigationView` (if this view is presented modally or as part of a navigation stack) or directly a `Form`.
    *   `Form`:
        *   **Model Management Section (`Section("Ollama Model Management")`):**
            *   `if viewModel.isModelListLoading`:
                *   `ProgressView("Loading models...")`
            *   `Picker("Select Model", selection: $viewModel.selectedModelName)`:
                *   Iterate over `viewModel.availableModels` (which might be `[OllamaTag]` or `[String]`).
                *   `Text(model.name).tag(model.name as String?)`
            *   Display current `selectedModelName` if needed.
            *   Button to "Refresh Model List" (`action: viewModel.fetchAvailableModels`).
            *   *(Future: List of all models with options to pull new ones or delete existing ones. This might involve a separate sub-view or more complex list items.)*
            *   `if let error = viewModel.modelManagementError`: Display `Text(error).foregroundColor(.red)`.
        *   **TTS Settings Section (`Section("Text-to-Speech (TTS)")`) - Future:**
            *   `Toggle("Enable TTS", isOn: $viewModel.isTTSEnabled)`.
            *   `Picker("Select Voice", selection: $viewModel.selectedVoiceIdentifier)`:
                *   Iterate over `viewModel.availableVoices`.
                *   `Text(voice.name).tag(voice.identifier as String?)`
            *   `HStack` for Speech Rate:
                *   `Text("Speech Rate")`
                *   `Slider(value: $viewModel.speechRate, in: 0.1...2.0)` (example range)
        *   **Other Application Settings Section (Future):**
            *   Theme selection, font size, etc.
    *   `.navigationTitle("Settings")` (if using NavigationView).
    *   `.onAppear(perform: viewModel.loadCurrentSettings)`: To fetch initial data when the view appears.

**Key UI Elements & Interactions:**

*   **Model Picker:** Allows users to select from the list of `viewModel.availableModels`.
*   **Refresh Button:** Triggers `viewModel.fetchAvailableModels()`.
*   **Loading/Error Indicators:** Provides feedback on ongoing operations or issues from `viewModel`.
*   **(Future) TTS Controls:** Toggles, pickers, and sliders for voice, rate, and enabling TTS.

**How it will be used:**

*   Typically presented modally, as a sheet, or as a tab in the main application interface (`ContentView`).
*   Relies on `SettingsViewModel` to fetch data (e.g., model list from `ModelManager`) and handle actions (e.g., updating selected model in `ModelManager`).
*   Changes made in this view (like selecting a model) will be reflected in other parts of the app (e.g., `ChatView` using the newly selected model) through the shared ViewModels or Services (`ModelManager`).

**Initial Implementation Notes (from placeholder):**

```swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel() // Assuming SettingsViewModel is properly initialized with its dependencies (ModelManager, TTSManager)

    var body: some View {
        Form {
            Section("Ollama Model Management") {
                if viewModel.isModelListLoading {
                    HStack {
                        ProgressView()
                        Text("Loading available models...")
                    }
                } else {
                    Picker("Current Model", selection: $viewModel.selectedModelName) {
                        ForEach(viewModel.availableModels, id: \.self) { modelName in
                            Text(modelName).tag(modelName as String?)
                        }
                    }
                    .onChange(of: viewModel.selectedModelName) { newValue in
                        if let newModel = newValue {
                            // viewModel.updateSelectedModel(newModel) // ViewModel should handle saving this
                        }
                    }
                }

                Button("Refresh Model List") {
                    viewModel.fetchAvailableModels()
                }

                if let error = viewModel.modelManagementError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            
            // Placeholder for future TTS settings
            /*
            Section("Text-to-Speech (TTS)") {
                Toggle("Enable TTS", isOn: $viewModel.isTTSEnabled)
                // Add Picker for voice, Slider for rate etc.
            }
            */
        }
        .navigationTitle("Settings") // Assuming it's in a NavigationView
        .onAppear {
            viewModel.loadCurrentSettings()
        }
    }
}
```
This provides a more concrete starting point for the actual implementation based on the description.
