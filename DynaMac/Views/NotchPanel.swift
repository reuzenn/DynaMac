import Foundation
import AppKit
import SwiftUI

/// Custom NSHostingView that intercepts trackpad gestures and delivers native drag-and-drop file staging
public class IslandHostingView<Content: View>: NSHostingView<Content> {
    @MainActor public required init(rootView: Content) {
        super.init(rootView: rootView)
        registerDragTypes()
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        registerDragTypes()
    }
    
    private func registerDragTypes() {
        registerForDraggedTypes([
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    public override func scrollWheel(with event: NSEvent) {
        NotchViewModel.shared.handleScroll(event: event)
        super.scrollWheel(with: event)
    }
    
    // MARK: - Native AppKit Dragging Destination
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(in: sender.draggingPasteboard) else { return [] }
        let screenPoint = NSEvent.mouseLocation
        let zone = NotchWindowController.shared.currentInteractiveRect()
        
        if zone.contains(screenPoint) {
            DispatchQueue.main.async {
                NotchViewModel.shared.handleDropTargetChanged(true)
            }
            return .copy
        }
        return []
    }
    
    public override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasFileURLs(in: sender.draggingPasteboard) else { return [] }
        let screenPoint = NSEvent.mouseLocation
        let zone = NotchWindowController.shared.currentInteractiveRect()
        
        if zone.contains(screenPoint) {
            if !NotchViewModel.shared.isDropTargeted {
                DispatchQueue.main.async {
                    NotchViewModel.shared.handleDropTargetChanged(true)
                }
            }
            return .copy
        } else {
            if NotchViewModel.shared.isDropTargeted {
                DispatchQueue.main.async {
                    NotchViewModel.shared.handleDropTargetChanged(false)
                }
            }
            return []
        }
    }
    
    public override func draggingExited(_ sender: NSDraggingInfo?) {
        DispatchQueue.main.async {
            NotchViewModel.shared.handleDropTargetChanged(false)
        }
    }
    
    public override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        hasFileURLs(in: sender.draggingPasteboard)
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = extractFileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else {
            DispatchQueue.main.async {
                NotchViewModel.shared.handleDropTargetChanged(false)
            }
            return false
        }
        
        DispatchQueue.main.async {
            HapticService.play(.snap)
            NotchViewModel.shared.handleDropTargetChanged(false)
            NotchViewModel.shared.handleFilesDropped(urls)
        }
        return true
    }
    
    private func hasFileURLs(in pasteboard: NSPasteboard) -> Bool {
        if let types = pasteboard.types {
            let fileTypeNames = [
                NSPasteboard.PasteboardType.fileURL.rawValue,
                "public.file-url",
                "NSFilenamesPboardType"
            ]
            for t in types {
                if fileTypeNames.contains(t.rawValue) { return true }
            }
        }
        return pasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }
    
    private func extractFileURLs(from pasteboard: NSPasteboard) -> [URL] {
        var results: [URL] = []
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for u in urls where u.isFileURL {
                let standard = u.standardizedFileURL
                if !results.contains(standard) { results.append(standard) }
            }
        }
        
        if results.isEmpty,
           let paths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            for p in paths {
                let u = URL(fileURLWithPath: p).standardizedFileURL
                if !results.contains(u) { results.append(u) }
            }
        }
        
        if results.isEmpty,
           let string = pasteboard.string(forType: .fileURL),
           let u = URL(string: string)?.standardizedFileURL, u.isFileURL {
            results.append(u)
        }
        
        return results
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
        
        // Register for file drags directly on panel
        self.registerForDraggedTypes([
            .fileURL,
            .URL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("NSFilenamesPboardType")
        ])
        
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
