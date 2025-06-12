import Foundation
import SwiftUI

// MARK: - String Extensions
extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !self.trimmed().isEmpty
    }
    
    func limitedTo(_ maxLength: Int) -> String {
        if self.count <= maxLength {
            return self
        }
        return String(self.prefix(maxLength)) + "..."
    }
}

// MARK: - Date Extensions
extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - UserDefaults Extensions
extension UserDefaults {
    struct Keys {
        static let ollamaURL = "ollamaURL"
        static let defaultModel = "defaultModel"
        static let ttsEnabled = "ttsEnabled"
        static let ttsVoice = "ttsVoice"
        static let ttsRate = "ttsRate"
        static let chatHistory = "chatHistory"
        static let windowSize = "windowSize"
    }
}

// MARK: - Color Extensions
extension Color {
    static let messageBackground = Color(NSColor.controlBackgroundColor)
    static let userMessageBackground = Color.blue
    static let assistantMessageBackground = Color(NSColor.quaternaryLabelColor)
}

// MARK: - macOS Specific Extensions
#if os(macOS)
extension NSColor {
    static let messageBackground = NSColor.controlBackgroundColor
}
#endif
