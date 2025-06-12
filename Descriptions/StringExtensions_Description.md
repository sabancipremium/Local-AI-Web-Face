# File Description: StringExtensions.swift

**Path:** `Local-AI-Web-Face/Local-AI-Web-Face/Extensions/StringExtensions.swift`

**Purpose:**

This file will contain useful extensions to the built-in `String` type. These extensions can provide convenient helper methods for common string manipulations or validations needed throughout the application.

**Potential Extensions:**

*   **`isBlank: Bool`**
    *   A computed property to check if a string is empty or contains only whitespace and newline characters.
    *   **Example Usage:** `if myString.isBlank { // do something }`
    *   **Implementation:** `return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`

*   **`trimmed: String`**
    *   A computed property that returns a new string with leading and trailing whitespace and newline characters removed.
    *   **Example Usage:** `let cleanString = myString.trimmed`
    *   **Implementation:** `return self.trimmingCharacters(in: .whitespacesAndNewlines)`

*   **`isValidURL: Bool`**
    *   A computed property to check if the string represents a valid URL.
    *   **Example Usage:** `if userInput.isValidURL { // open link }`
    *   **Implementation:** `return URL(string: self) != nil` (basic check, could be more robust with regex or `NSPredicate` for stricter validation if needed).

*   **`capitalizingFirstLetter(): String`**
    *   A method to return a new string with only the first letter capitalized.
    *   **Example Usage:** `let sentence = "hello world".capitalizingFirstLetter()`
    *   **Implementation:** `return prefix(1).capitalized + dropFirst()`

*   **`lines: [String]`**
    *   A computed property to split a multi-line string into an array of strings, one for each line.
    *   **Example Usage:** `for line in textBlock.lines { print(line) }`
    *   **Implementation:** `return self.components(separatedBy: .newlines)`

*   **(Potentially) `matches(regex: String): Bool`**
    *   A method to check if the string matches a given regular expression.
    *   Requires more complex implementation using `NSRegularExpression`.

**How it will be used:**

*   These extensions can be called on any String instance throughout the codebase.
*   For example, `viewModel.inputText.isBlank` could be used to disable a send button if the input field is empty or just whitespace.
*   `messageContent.trimmed` could be used before processing or displaying text.

**Example Structure:**

```swift
import Foundation

extension String {

    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Add other extensions as needed...
}
```

This file helps keep string utility functions organized and easily accessible, promoting cleaner and more readable code in other parts of the application.
