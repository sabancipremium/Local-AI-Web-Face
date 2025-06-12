# File Description: ContentView.swift

**Path:** `Local-AI-Web-Face/Local-AI-Web-Face/ContentView.swift`

**Purpose:**

This file defines `ContentView`, which serves as the main container view for the application's user interface. It's responsible for laying out the primary sections of the app, such as the chat interface, avatar display, and providing navigation to settings or other features.

**Structure (`ContentView` struct):**

*   Conforms to `View`.
*   **Environment Objects:**
    *   `@EnvironmentObject var modelManager: ModelManager`
    *   `@EnvironmentObject var ttsManager: TTSManager`
    *   `@EnvironmentObject var settingsViewModel: SettingsViewModel`
    *   `@EnvironmentObject var chatViewModel: ChatViewModel`
    *   (These are injected from `Local_AI_Web_FaceApp.swift`)
*   **State (Optional, for managing local UI state like sheet presentation):**
    *   `@State private var showingSettings: Bool = false`
*   **Body Layout (Conceptual - could vary based on desired UI):**

    **Option 1: Simple Chat-focused Layout (macOS Sidebar common)**
    ```swift
    var body: some View {
        NavigationView {
            // Sidebar (optional, could list chats or models)
            List {
                Text("Models") // Placeholder
                // Potentially list models from modelManager or settingsViewModel
            }
            .listStyle(SidebarListStyle())

            // Main content area
            ChatView()
                // .environmentObject(chatViewModel) // Already in environment
        }
        .toolbar {
            ToolbarItem(placement: .navigation) { // For sidebar toggle on macOS
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
            ToolbarItem(placement: .automatic) { // Or .primaryAction for macOS
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                // .environmentObject(settingsViewModel) // Already in environment
                // .environmentObject(modelManager)
                // .environmentObject(ttsManager)
        }
    }

    private func toggleSidebar() {
        #if os(macOS)
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
    ```

    **Option 2: Integrated Layout with Avatar**
    ```swift
    var body: some View {
        HSplitView { // Or VStack/HStack depending on desired layout
            ChatView()
                // .environmentObject(chatViewModel)
                .frame(minWidth: 300, idealWidth: 500, maxWidth: .infinity)
            
            AvatarView(ttsManager: ttsManager /*, chatViewModel: chatViewModel */)
                .frame(width: 250) // Example fixed size for avatar panel
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                // .environmentObject(settingsViewModel)
                // .environmentObject(modelManager)
                // .environmentObject(ttsManager)
        }
    }
    ```

**Key Responsibilities:**

*   **Root UI Structure:** Assembles the main visual components of the app (`ChatView`, `AvatarView`, navigation elements).
*   **Navigation:** Provides access to other parts of the application, like a `SettingsView` (often presented as a sheet or in a separate window on macOS).
*   **Passing Environment Objects:** While it receives them, its main role here is to ensure its child views also have access if they aren't directly using `@EnvironmentObject` themselves (though direct use is preferred for children that need them).
*   **Toolbar/Menu Items:** May define global actions or navigation options in a toolbar or menu.

**How it will be used:**

*   It's the first view instantiated by `Local_AI_Web_FaceApp` within the `WindowGroup`.
*   It acts as the primary container and orchestrator for the user-facing views.

**Dependencies:**

*   `ChatView.swift`
*   `SettingsView.swift`
*   `AvatarView.swift` (if included directly)
*   The shared `ModelManager`, `TTSManager`, `SettingsViewModel`, `ChatViewModel` (via `@EnvironmentObject`).

This view is crucial for defining the overall layout and flow of the application. The exact implementation of its `body` will depend on the desired user experience and visual design.
