# File Description: SettingsViewModel.swift

**Path:** `Local-AI-Web-Face/ViewModels/SettingsViewModel.swift`

**Purpose:**

This file defines the `SettingsViewModel`, responsible for managing the state and logic related to application settings. This primarily includes Ollama model management (listing, selecting) and potentially TTS (Text-to-Speech) configurations.

**Structure (`SettingsViewModel` class):**

*   Conforms to `ObservableObject` for SwiftUI view updates.
*   **Published Properties:**
    *   `@Published var availableModels: [String] = []`: A list of names of Ollama models available locally.
    *   `@Published var selectedModel: String?`: The currently selected Ollama model name. This should be synchronized with `ModelManager`.
    *   `@Published var isModelListLoading: Bool = false`: Indicates if the list of models is currently being fetched.
    *   `@Published var modelManagementError: String? = nil`: For displaying errors related to model operations.
    *   *(Future TTS Settings)*
        *   `@Published var availableVoices: [String] = []` (or `AVSpeechSynthesisVoice` objects)
        *   `@Published var selectedVoice: String?`
        *   `@Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate`
        *   `@Published var isTTSEnabled: Bool = true`
*   **Dependencies (Services):**
    *   `modelManager: ModelManager` (instance, likely an `@ObservedObject` or passed in)
    *   `ttsManager: TTSManager` (instance, for future TTS settings)
*   **Private Properties:**
    *   `cancellables = Set<AnyCancellable>()`: For Combine subscriptions.

**Key Responsibilities & Functions:**

*   **`fetchAvailableModels()`:**
    *   Sets `isModelListLoading = true`.
    *   Calls a function in `ModelManager` to get the list of locally available Ollama models.
    *   Updates `availableModels` with the result.
    *   Handles errors and updates `modelManagementError`.
    *   Sets `isModelListLoading = false` on completion or error.
*   **`selectModel(modelName: String)`:**
    *   Calls a function in `ModelManager` to set the chosen model as active.
    *   Updates `selectedModel` based on the success of the operation in `ModelManager`.
*   **`loadCurrentSettings()`:**
    *   Called on initialization to fetch the current list of models and the currently selected model from `ModelManager`.
    *   (Future) Load current TTS settings from `TTSManager` or `UserDefaults`.
*   **Synchronization with `ModelManager`:**
    *   Observe changes in `ModelManager.availableModels` and `ModelManager.selectedModel` to keep the ViewModel's properties in sync.
*   **(Future TTS Functions):**
    *   `fetchAvailableVoices()`: Get system voices via `TTSManager`.
    *   `selectVoice(voiceIdentifier: String)`: Update TTS voice preference.
    *   `updateSpeechRate(rate: Float)`: Update TTS speech rate.
    *   `toggleTTS(enabled: Bool)`: Enable/disable TTS.

**How it will be used:**

*   The `SettingsView` will create an instance of `SettingsViewModel` (likely as a `@StateObject` or `@ObservedObject`).
*   UI elements in `SettingsView` (e.g., `Picker` for model selection, toggles for TTS) will bind to the published properties of `SettingsViewModel`.
*   Actions in `SettingsView` (e.g., selecting a model) will call functions on `SettingsViewModel`.
*   The `ChatViewModel` might observe `selectedModel` from this ViewModel (or directly from `ModelManager`) to know which model to use for chat requests.
