# File Description: TTSManager.swift

**Path:** `Local-AI-Web-Face/Services/TTSManager.swift`

**Purpose:**

This file defines the `TTSManager` (Text-to-Speech Manager) class, an `ObservableObject` responsible for handling all text-to-speech functionalities within the application. It will use Apple's `AVFoundation` framework, specifically `AVSpeechSynthesizer`, to convert text (LLM responses) into spoken audio.

**Structure (`TTSManager` class):**

*   Conforms to `ObservableObject` to publish changes (e.g., speaking status, available voices).
*   Implements `AVSpeechSynthesizerDelegate` to receive callbacks about speech events (start, finish, pause, errors).
*   **Published Properties:**
    *   `@Published var isSpeaking: Bool = false`: Indicates if TTS is currently active.
    *   `@Published var availableVoices: [AVSpeechSynthesisVoice] = []`: A list of available system voices.
    *   `@Published var selectedVoiceIdentifier: String?`: The identifier of the currently selected voice (persisted in `UserDefaults`).
    *   `@Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate`: The current speech rate (persisted).
    *   `@Published var isTTSEnabled: Bool = true`: Global toggle for enabling/disabling TTS (persisted).
*   **Private Properties:**
    *   `speechSynthesizer = AVSpeechSynthesizer()`: The core object for speech synthesis.
    *   `userDefaultsKeySelectedVoice = "selectedTTSVoiceIdentifier"`
    *   `userDefaultsKeySpeechRate = "speechRateTTS"`
    *   `userDefaultsKeyTTSEnabled = "isTTSEnabled"`

**Key Responsibilities & Functions:**

*   **`init()`:**
    *   Sets `speechSynthesizer.delegate = self`.
    *   Calls `loadSettings()` to retrieve persisted voice, rate, and enabled status.
    *   Calls `fetchAvailableVoices()`.
*   **`speak(text: String)`:**
    *   Checks if `isTTSEnabled` is true. If not, returns early.
    *   If `isSpeaking`, may choose to stop current speech or queue.
    *   Creates an `AVSpeechUtterance` with the provided text.
    *   Sets the `voice` property of the utterance using `selectedVoiceIdentifier` (or default if nil).
    *   Sets the `rate` property of the utterance using `speechRate`.
    *   Calls `speechSynthesizer.speak(utterance)`.
*   **`stopSpeaking()`:**
    *   Calls `speechSynthesizer.stopSpeaking(at: .immediate)` (or `.word` boundary).
*   **`pauseSpeaking()`:**
    *   Calls `speechSynthesizer.pauseSpeaking(at: .immediate)`.
*   **`continueSpeaking()`:**
    *   Calls `speechSynthesizer.continueSpeaking()`.
*   **`fetchAvailableVoices()`:**
    *   Populates `availableVoices` with `AVSpeechSynthesisVoice.speechVoices()`.
    *   Ensures the `selectedVoiceIdentifier` is still valid; if not, resets to default.
*   **`selectVoice(identifier: String?)`:**
    *   Updates `selectedVoiceIdentifier` and saves it.
*   **`setSpeechRate(rate: Float)`:**
    *   Updates `speechRate` (clamped to valid min/max) and saves it.
*   **`toggleTTSEnabled(enabled: Bool)`:**
    *   Updates `isTTSEnabled` and saves it.
    *   If disabling while speaking, calls `stopSpeaking()`.
*   **Persistence (`saveSettings()`, `loadSettings()`):**
    *   Private methods to save/load `selectedVoiceIdentifier`, `speechRate`, and `isTTSEnabled` from `UserDefaults`.

**`AVSpeechSynthesizerDelegate` Methods Implementation:**

*   `speechSynthesizer(_:didStart:)`: Sets `isSpeaking = true`.
*   `speechSynthesizer(_:didFinish:)`: Sets `isSpeaking = false`.
*   `speechSynthesizer(_:didPause:)`: Updates state if needed.
*   `speechSynthesizer(_:didContinue:)`: Updates state if needed.
*   `speechSynthesizer(_:didCancel:)`: Sets `isSpeaking = false`.

**How it will be used:**

*   Instantiated as a shared object (e.g., in the App's main struct or as an environment object) and injected into ViewModels (`ChatViewModel`, `SettingsViewModel`).
*   `ChatViewModel` will call `speak(text:)` when a new message from the bot is received and TTS is enabled.
*   `SettingsViewModel` will use it to:
    *   Display `availableVoices` in a picker.
    *   Allow users to set `selectedVoiceIdentifier` and `speechRate`.
    *   Provide a toggle for `isTTSEnabled`.
*   The `AvatarView` might observe `isSpeaking` to trigger speaking animations.
