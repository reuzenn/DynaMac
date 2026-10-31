import Foundation
import AppKit
import SwiftUI

/// Custom NSHostingView that intercepts trackpad gestures and delivers fluid interaction
public class IslandHostingView<Content: View>: NSHostingView<Content> {
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    public override func scrollWheel(with event: NSEvent) {
        NotchViewModel.shared.handleScroll(event: event)
        super.scrollWheel(with: event)
    }
}

/// Floating, non-activating NSPanel that hugs the physical notch
public final class NotchPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .statusBar + 1
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        
        // Ensure it appears across all spaces and full-screen apps
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
    }
    
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}
