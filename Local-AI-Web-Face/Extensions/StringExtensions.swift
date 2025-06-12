// StringExtensions.swift
// Local-AI-Web-Face
//
// String utility extensions

import Foundation

extension String {
    /// Returns the string with leading and trailing whitespace removed
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns true if the string is not empty after trimming whitespace
    var isNotEmpty: Bool {
        return !self.trimmed().isEmpty
    }
    
    /// Limits the string to a maximum length, adding ellipsis if truncated
    func limitedTo(_ maxLength: Int) -> String {
        if self.count <= maxLength {
            return self
        }
        return String(self.prefix(maxLength)) + "..."
    }
    
    /// Returns true if the string contains only whitespace characters
    var isBlank: Bool {
        return self.trimmed().isEmpty
    }
    
    /// Capitalizes the first letter of the string
    func capitalizedFirst() -> String {
        guard !isEmpty else { return self }
        return prefix(1).capitalized + dropFirst()
    }
    
    /// Removes all instances of a specific character
    func removing(_ character: Character) -> String {
        return self.filter { $0 != character }
    }
    
    /// Safe subscript to prevent index out of bounds
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    /// Validates if string is a valid URL
    var isValidURL: Bool {
        return URL(string: self) != nil
    }
    
    /// Converts markdown-style formatting to plain text (basic implementation)
    func stripMarkdown() -> String {
        return self
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "#", with: "")
    }
}
