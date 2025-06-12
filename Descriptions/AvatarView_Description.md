# File Description: AvatarView.swift

**Path:** `Local-AI-Web-Face/Views/AvatarView.swift`

**Purpose:**

This file will define the `AvatarView`, a SwiftUI view responsible for displaying and animating the 2D avatar. The avatar is intended to provide a more engaging visual representation during interactions with the LLM, potentially reacting to speech and conversation context.

**Structure (`AvatarView` struct):**

*   Conforms to `View`.
*   **State Management/Dependencies:**
    *   `@ObservedObject var ttsManager: TTSManager`: To know when TTS is active (for speaking animations).
    *   `@ObservedObject var chatViewModel: ChatViewModel`: Potentially to get context from the chat (e.g., if the LLM is thinking, or the sentiment of the response, for more advanced animations - future).
    *   `@State private var currentAnimation: AnimationType = .idle`: An enum to manage different animation states (e.g., idle, speaking, thinking).
*   **SpriteKit Integration (Primary approach for 2D animation):**
    *   It will likely use a `SpriteView` from SwiftUI to host a SpriteKit scene (`SKScene`).
    *   `AvatarScene: SKScene`: A custom `SKScene` subclass that will manage the avatar's `SKSpriteNode`s, textures, and `SKAction`s for animations.
*   **Body Layout (Conceptual):**
    *   `SpriteView(scene: avatarScene)`
        *   The `avatarScene` would be an instance of `AvatarScene`, configured with the necessary assets.
    *   Potentially overlay SwiftUI elements if needed, though most visual aspects will be within the SpriteKit scene.

**Key UI Elements & Logic within `AvatarScene`:**

*   **Avatar Node (`SKSpriteNode`):** The main visual element for the avatar.
*   **Texture Atlases:** For different animation frames (e.g., idle frames, speaking frames with lip sync variations).
*   **Animation Actions (`SKAction`):**
    *   `idleAnimation()`: An action that loops through idle frames.
    *   `speakingAnimation()`: An action that loops through speaking frames (lip sync). This would be triggered when `ttsManager.isSpeaking` is true.
    *   `(Future) thinkingAnimation()`, `reactingAnimation(sentiment: ...)`.
*   **State Machine (Implicit or Explicit):**
    *   The scene will need logic to transition between animations based on `ttsManager.isSpeaking` and other potential triggers.
    *   This could be managed by observing changes in the `ttsManager` and updating the `currentAnimation` state, which then triggers the corresponding `SKAction` on the avatar node.

**Key Responsibilities:**

*   **Displaying the Avatar:** Rendering the 2D avatar graphic.
*   **Idle Animation:** Playing a default animation when the avatar is not speaking or actively doing something else.
*   **Speaking Animation:** Synchronizing a speaking animation (e.g., lip movement) with the TTS output from `TTSManager`.
*   **(Future) Contextual Animations:** Reacting to chat events, LLM processing states, or message sentiment with different expressions or animations.

**How it will be used:**

*   An instance of `AvatarView` will be placed in the main application UI, likely alongside or near the `ChatView`.
*   It will observe the `TTSManager` to know when to play speaking animations.
*   The actual animation logic (frame sequences, timing) will be encapsulated within the `AvatarScene` and its helper methods.

**Challenges & Considerations:**

*   **Asset Creation:** Requires 2D avatar graphics and animation frames.
*   **Lip Sync:** True lip synchronization can be complex. Initial versions might use a generic speaking animation. More advanced versions could attempt to map phonemes or speech volume to different mouth shapes (requires deeper `AVFoundation` analysis or simpler heuristics).
*   **Performance:** Ensure animations are smooth and don't excessively consume resources, especially if using complex SpriteKit scenes.
*   **Integration with Live2D Cubism SDK (Alternative/Advanced):** As mentioned in blueprints, this is a more powerful but also more complex option for advanced 2D animations. Initial implementation will likely stick to SpriteKit for simplicity.

**Initial Implementation Notes (from placeholder):**

```swift
import SwiftUI
import SpriteKit

// Basic enum for animation states
enum AvatarAnimationState {
    case idle
    case speaking
    // case thinking // Future
}

class AvatarScene: SKScene {
    private var avatarNode: SKSpriteNode?
    // Preload textures and actions here
    private var idleFrames: [SKTexture] = []
    private var speakingFrames: [SKTexture] = []

    override func didMove(to view: SKView) {
        // Setup scene, avatar node, load textures
        // For example:
        // let texture = SKTexture(imageNamed: "avatar_idle_01") // Placeholder
        // avatarNode = SKSpriteNode(texture: texture)
        // avatarNode?.position = CGPoint(x: frame.midX, y: frame.midY)
        // addChild(avatarNode!)
        // playAnimation(.idle) // Start with idle
    }

    func playAnimation(_ state: AvatarAnimationState) {
        avatarNode?.removeAllActions()
        switch state {
        case .idle:
            // if !idleFrames.isEmpty {
            //     avatarNode?.run(SKAction.repeatForever(SKAction.animate(with: idleFrames, timePerFrame: 0.1)))
            // } else {
            //     // Fallback or placeholder if frames not loaded
            // }
            avatarNode?.texture = SKTexture(imageNamed: "avatar_idle_placeholder") // Placeholder
        case .speaking:
            // if !speakingFrames.isEmpty {
            //     avatarNode?.run(SKAction.repeatForever(SKAction.animate(with: speakingFrames, timePerFrame: 0.07)))
            // } else {
            //     // Fallback
            // }
            avatarNode?.texture = SKTexture(imageNamed: "avatar_speaking_placeholder") // Placeholder
        }
    }
}

struct AvatarView: View {
    // Assuming TTSManager is provided as an EnvironmentObject or ObservedObject
    @ObservedObject var ttsManager: TTSManager // Needs to be initialized and passed
    // @ObservedObject var chatViewModel: ChatViewModel // For future context

    // Create and configure the scene
    var scene: AvatarScene {
        let scene = AvatarScene()
        scene.size = CGSize(width: 200, height: 200) // Example size
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear // Or some background color
        return scene
    }

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .frame(width: 200, height: 200) // Match scene size
            .onChange(of: ttsManager.isSpeaking) { speaking in
                // This is where you'd tell the scene to change animation
                // However, direct calls to scene methods from here are tricky.
                // The scene itself should ideally observe the TTSManager or have a binding.
                // For now, a simple approach might be to recreate the scene or pass a binding.
                // A better way is for AvatarScene to also observe TTSManager if possible,
                // or pass a @State variable from AvatarView into AvatarScene that changes.
                
                // Let's assume AvatarScene has a method that can be called, or it observes ttsManager directly.
                // This is a common challenge bridging SwiftUI state to SKScene updates.
                // One way: scene.playAnimation(speaking ? .speaking : .idle)
                // This requires the 'scene' var to be a @State or for the scene to be an ObservableObject itself.
            }
            // A more robust way for the scene to react:
            // Pass ttsManager into the scene's initializer or set it as a property, 
            // and use Combine within the scene to subscribe to ttsManager.isSpeaking changes.
    }
}

// Example of how AvatarScene could observe TTSManager
/*
class ReactiveAvatarScene: SKScene {
    private var ttsSubscription: AnyCancellable?
    private var ttsManager: TTSManager? // Set this from AvatarView

    func setup(ttsManager: TTSManager) {
        self.ttsManager = ttsManager
        ttsSubscription = ttsManager.$isSpeaking.sink { [weak self] speaking in
            self?.playAnimation(speaking ? .speaking : .idle)
        }
    }
    // ... rest of AvatarScene logic ...
    deinit {
        ttsSubscription?.cancel()
    }
}
*/

```
This provides a more concrete starting point, highlighting the SpriteKit integration and the need to react to `TTSManager` state changes.
