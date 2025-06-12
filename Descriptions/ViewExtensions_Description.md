# File Description: ViewExtensions.swift

**Path:** `Local-AI-Web-Face/Local-AI-Web-Face/Extensions/ViewExtensions.swift`

**Purpose:**

This file will contain custom extensions to SwiftUI's `View` protocol. These extensions can define reusable view modifiers, helper functions for layout, or other UI-related utilities to simplify view construction and promote a consistent look and feel across the application.

**Potential Extensions:**

*   **`.padding(_ edges: Edge.Set, _ length: CGFloat?)` (Conditional Padding)**
    *   A modifier that applies padding only if the length is not nil.
    *   **Example Usage:** `Text("Hello").padding(.all, shouldPad ? 10 : nil)`
    *   **Implementation:**
        ```swift
        func padding(_ edges: Edge.Set, _ length: CGFloat?) -> some View {
            Group {
                if let length = length {
                    self.padding(edges, length)
                } else {
                    self
                }
            }
        }
        ```

*   **`.conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View`**
    *   Applies a given `ViewModifier` only if a condition is true.
    *   **Example Usage:** `MyView().conditionalModifier(isHighlighted, modifier: HighlightModifier())`
    *   **Implementation:**
        ```swift
        @ViewBuilder
        func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
            if condition {
                self.modifier(modifier)
            } else {
                self
            }
        }
        ```

*   **`.hideKeyboard()` (Global Keyboard Dismissal)**
    *   A utility function to dismiss the keyboard programmatically.
    *   **Example Usage:** `Button("Done") { self.hideKeyboard() }`
    *   **Implementation (macOS might differ slightly, this is more common for iOS but adaptable):**
        ```swift
        #if canImport(UIKit)
        func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        #elseif canImport(AppKit)
        // macOS specific way to resign first responder if applicable
        // For instance, NSApp.keyWindow?.makeFirstResponder(nil)
        // This might need to be more context-aware on macOS.
        func hideKeyboard() {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        #endif
        ```
        *(Note: For macOS, direct keyboard dismissal is less common than managing focus. This might be adapted or used for specific scenarios like ending text editing.)*

*   **Custom Styling Modifiers:**
    *   e.g., `.primaryButtonStyle()`, `.cardStyle()` if you have common styling patterns.
    *   **Example:**
        ```swift
        struct PrimaryButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            }
        }

        func primaryButtonStyle() -> some View {
            self.buttonStyle(PrimaryButtonStyle())
        }
        ```

*   **`.onFirstAppear(perform: () -> Void)`**
    *   A modifier that performs an action only the first time the view appears.
    *   **Implementation:** Requires a `@State` variable within a helper struct that conforms to `ViewModifier`.

**How it will be used:**

*   These extensions can be applied to any `View` in SwiftUI.
*   They help to reduce boilerplate code in individual views and ensure consistency.
*   For example, instead of writing `if condition { view.modifier(SomeModifier()) } else { view }` repeatedly, you can use `.conditionalModifier(condition, modifier: SomeModifier())`.

**Example Structure:**

```swift
import SwiftUI

extension View {

    @ViewBuilder
    func conditionalModifier<M: ViewModifier>(_ condition: Bool, modifier: M) -> some View {
        if condition {
            self.modifier(modifier)
        } else {
            self
        }
    }

    // Add other view extensions here...
    
    // Example for macOS keyboard dismissal (might need refinement for specific use cases)
    func resignFirstResponder() {
        DispatchQueue.main.async {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }
}
```

This file will evolve as common UI patterns and needs are identified during development.
