// ViewExtensions.swift
// Local-AI-Web-Face
//
// SwiftUI View utility extensions

import SwiftUI

extension View {
    /// Conditionally applies a modifier
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies padding only if the value is not nil
    func conditionalPadding(_ edges: Edge.Set, _ length: CGFloat?) -> some View {
        Group {
            if let length = length {
                self.padding(edges, length)
            } else {
                self
            }
        }
    }
    
    /// Applies a background color conditionally
    func conditionalBackground(_ color: Color, when condition: Bool) -> some View {
        self.background(condition ? color : Color.clear)
    }
    
    /// Applies a modifier conditionally
    func conditionalModifier<M: ViewModifier>(_ modifier: M, when condition: Bool) -> some View {
        Group {
            if condition {
                self.modifier(modifier)
            } else {
                self
            }
        }
    }
    
    /// Creates a card-like appearance with shadow and corner radius
    func cardStyle(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 4) -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
    
    /// Adds a subtle border
    func subtleBorder(_ color: Color = Color.gray.opacity(0.3), width: CGFloat = 1) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Dismisses keyboard on macOS (resignFirstResponder equivalent)
    func resignFirstResponder() -> some View {
        self.onTapGesture {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
    
    /// Adds a loading overlay
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                    }
                    .allowsHitTesting(true)
                }
            }
        )
    }
    
    /// Adds a pulse animation effect
    func pulse(duration: Double = 1.0) -> some View {
        self.scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: true
            )
    }
    
    /// Adds a shake animation for errors
    func shake(_ trigger: Bool) -> some View {
        self.offset(x: trigger ? 5 : 0)
            .animation(
                trigger ? Animation.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true) : .default,
                value: trigger
            )
    }
}

// MARK: - macOS Specific Extensions

#if os(macOS)
extension View {
    /// Sets the window title for macOS
    func windowTitle(_ title: String) -> some View {
        self.navigationTitle(title)
    }
    
    /// Adds macOS-specific toolbar styling
    func macOSToolbar() -> some View {
        self.toolbar {
            ToolbarItem(placement: .automatic) {
                Spacer()
            }
        }
    }
}
#endif
