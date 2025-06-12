# File Description: ModelManager.swift

**Path:** `Local-AI-Web-Face/Services/ModelManager.swift`

**Purpose:**

This file defines the `ModelManager` class, an `ObservableObject` responsible for managing the Ollama models available to the application. It acts as a centralized service for fetching model lists, handling model selection, and potentially initiating model downloads or deletions by interacting with `OllamaService`.

**Structure (`ModelManager` class):**

*   Conforms to `ObservableObject` to publish changes to its properties.
*   **Published Properties:**
    *   `@Published var availableModels: [OllamaTag] = []`: An array of `OllamaTag` objects (or a simpler struct/string if only names are needed initially) representing all locally downloaded Ollama models.
    *   `@Published var selectedModelName: String?`: The name of the currently active/selected model. This should be persisted (e.g., in `UserDefaults`).
    *   `@Published var isLoading: Bool = false`: Indicates if the manager is currently performing an operation like fetching models or changing a model.
    *   `@Published var errorMessage: String? = nil`: For displaying errors related to model management operations.
    *   `@Published var pullProgress: OllamaPullStatus? = nil`: To report progress when a model is being downloaded.
*   **Dependencies:**
    *   `ollamaService: OllamaService`: An instance of `OllamaService` to interact with the Ollama API.
*   **Private Properties:**
    *   `userDefaultsKeySelectedModel = "selectedOllamaModel"`: Key for persisting the selected model.
    *   `cancellables = Set<AnyCancellable>()`: For Combine subscriptions if needed for internal tasks.

**Key Responsibilities & Functions:**

*   **`init(ollamaService: OllamaService)`:**
    *   Initializes with an `OllamaService` instance.
    *   Calls `loadSelectedModel()` to retrieve the last used model from `UserDefaults`.
    *   Calls `fetchAvailableModels()` to populate the initial list.
*   **`fetchAvailableModels()`:**
    *   Sets `isLoading = true`, clears `errorMessage`.
    *   Uses `ollamaService.getAvailableModels()` to get the list of models.
    *   On success, updates `availableModels`.
    *   On failure, sets `errorMessage`.
    *   Sets `isLoading = false`.
*   **`selectModel(modelName: String)`:**
    *   Updates `selectedModelName` with the new model name.
    *   Calls `saveSelectedModel()` to persist this choice.
    *   *(Future: May involve telling Ollama to load this model if it's not already running, though Ollama typically loads on first use or via `/api/generate` or `/api/chat` specifying the model.)*
*   **`saveSelectedModel()`:**
    *   Saves the current `selectedModelName` to `UserDefaults`.
*   **`loadSelectedModel()`:**
    *   Loads the selected model name from `UserDefaults` and updates `selectedModelName`.
*   **`pullModel(modelName: String)`:**
    *   Sets `isLoading = true`, clears `errorMessage`, resets `pullProgress`.
    *   Uses `ollamaService.pullModel(modelName: modelName)`.
    *   Subscribes to the returned `AsyncThrowingStream` to update `pullProgress` with `OllamaPullStatus` updates.
    *   On completion, calls `fetchAvailableModels()` to refresh the list.
    *   On failure, sets `errorMessage`.
    *   Sets `isLoading = false` when the stream finishes or errors out.
*   **`deleteModel(modelName: String)`:**
    *   Sets `isLoading = true`, clears `errorMessage`.
    *   Uses `ollamaService.deleteModel(modelName: modelName)`.
    *   On success, calls `fetchAvailableModels()` to refresh the list. If the deleted model was selected, it might clear `selectedModelName` or select a default.
    *   On failure, sets `errorMessage`.
    *   Sets `isLoading = false`.

**How it will be used:**

*   Instantiated as a shared object (e.g., in the App's main struct or as an environment object) and injected into ViewModels that need it (`SettingsViewModel`, `ChatViewModel`).
*   `SettingsViewModel` will use it to display available models, allow selection, and trigger pull/delete operations.
*   `ChatViewModel` will observe `selectedModelName` (or get it from `SettingsViewModel`) to know which model to use for chat requests via `OllamaService`.
*   It centralizes the logic for model state, ensuring consistency across the app.
