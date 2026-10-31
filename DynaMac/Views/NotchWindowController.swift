import Foundation
import AppKit
import SwiftUI
import Combine

public final class NotchWindowController {
    public static let shared = NotchWindowController()
    
    private var panel: NotchPanel?
    private var hostingView: IslandHostingView<NotchContainerView>?
    private var cancellables = Set<AnyCancellable>()
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?
    
    private init() {}
    
    public func start() {
        guard panel == nil else { return }
        
        let geom = NotchManager.shared.currentGeometry
        let panelSize = IslandLayout.panelSize
        let panelFrame = NSRect(
            x: geom.centerX - (panelSize.width / 2),
            y: geom.topY - panelSize.height,
            width: panelSize.width,
            height: panelSize.height
        )
        
        let panel = NotchPanel(contentRect: panelFrame)
        let containerView = NotchContainerView()
        let hosting = IslandHostingView(rootView: containerView)
        hosting.frame = NSRect(origin: .zero, size: panelFrame.size)
        hosting.autoresizingMask = [.width, .height]
        
        panel.contentView = hosting
        panel.setFrame(panelFrame, display: true)
        
        // Start with ignoring mouse events outside the notch shape
        panel.ignoresMouseEvents = true
        panel.orderFrontRegardless()
        
        self.panel = panel
        self.hostingView = hosting
        
        setupEventMonitors()
        setupGeometryObserver()
    }
    
    private func setupGeometryObserver() {
        NotificationCenter.default.addObserver(
            forName: .notchGeometryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionPanel()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.repositionPanel()
        }
    }
    
    public func repositionPanel() {
        guard let panel = panel else { return }
        let geom = NotchManager.shared.currentGeometry
        let panelSize = IslandLayout.panelSize
        let newFrame = NSRect(
            x: geom.centerX - (panelSize.width / 2),
            y: geom.topY - panelSize.height,
            width: panelSize.width,
            height: panelSize.height
        )
        panel.setFrame(newFrame, display: true)
    }
    
    private func setupEventMonitors() {
        // Global mouse movement & drag tracking
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.evaluateMousePosition(event: event)
        }
        
        // Local mouse movement & drag tracking
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.evaluateMousePosition(event: event)
            return event
        }
        
        // Outside click detector when expanded
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            let vm = NotchViewModel.shared
            if vm.state.isExpanded {
                let mouseLoc = NSEvent.mouseLocation
                let interactiveRect = self.currentInteractiveRect()
                if !interactiveRect.contains(mouseLoc) {
                    vm.collapse()
                    self.panel?.ignoresMouseEvents = true
                }
            }
        }
        
        // ESC key detector to collapse
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC key
                if NotchViewModel.shared.state.isExpanded {
                    NotchViewModel.shared.collapse()
                    return nil
                }
            }
            return event
        }
    }
    
    /// Calculate the exact active bounding rect of the Dynamic Island in screen coordinates
    public func currentInteractiveRect() -> NSRect {
        let geom = NotchManager.shared.currentGeometry
        let vm = NotchViewModel.shared
        
        let islandSize: CGSize
        if vm.isDropTargeted {
            islandSize = IslandLayout.droppingSize(geom)
        } else {
            islandSize = IslandLayout.size(
                state: vm.state,
                compact: vm.compactActivity,
                hovering: vm.isHovering,
                stretch: vm.stretch,
                geometry: geom
            )
        }
        
        // Exact geometry matching the physical notch and expanded capsule - zero oversized padding
        let originX = geom.centerX - (islandSize.width / 2)
        let originY = geom.topY - islandSize.height
        return NSRect(x: originX, y: originY, width: islandSize.width, height: islandSize.height)
    }
    
    private func evaluateMousePosition(event: NSEvent) {
        guard let panel = panel else { return }
        let vm = NotchViewModel.shared
        let mouseLoc = NSEvent.mouseLocation
        
        let interactiveRect = currentInteractiveRect()
        let isInside = interactiveRect.contains(mouseLoc)
        
        if isInside {
            if panel.ignoresMouseEvents {
                panel.ignoresMouseEvents = false
            }
            vm.handleHoverChanged(true)
        } else {
            if !vm.isDropTargeted {
                if !panel.ignoresMouseEvents {
                    panel.ignoresMouseEvents = true
                }
                vm.handleHoverChanged(false)
            }
        }
    }
    
    deinit {
        if let monitor = globalMouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMouseMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localKeyMonitor { NSEvent.removeMonitor(monitor) }
    }
}
