import Foundation
import AppKit
import SwiftUI
import Combine

/// Power, screen visibility and user inactivity optimizer for notch rendering and background tasks
public final class DisplayStateService: ObservableObject {
    public static let shared = DisplayStateService()
    
    /// True when display is awake and visible
    @Published public private(set) var isScreenAwake: Bool = true
    
    /// True when the user has been inactive for more than idleTimeout (3 minutes)
    @Published public private(set) var isUserIdle: Bool = false
    
    /// Combined pause state for high-frequency animations (RGB cycle, visualizers)
    @Published public private(set) var isAnimationPaused: Bool = false
    
    private var idleCheckTimer: Timer?
    private let idleTimeout: TimeInterval = 180.0 // 3 minutes
    
    private init() {
        setupSleepObservers()
        startIdleMonitoring()
    }
    
    private func setupSleepObservers() {
        let ws = NSWorkspace.shared.notificationCenter
        
        ws.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isScreenAwake = false
            self?.updatePausedState()
        }
        
        ws.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isScreenAwake = true
            self?.userDidInteract()
            self?.updatePausedState()
        }
        
        ws.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isScreenAwake = false
            self?.updatePausedState()
        }
        
        ws.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isScreenAwake = true
            self?.userDidInteract()
            self?.updatePausedState()
        }
    }
    
    private func startIdleMonitoring() {
        // Lightweight check every 5 seconds to detect 3-minute inactivity
        let timer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.idleCheckTimer = timer
    }
    
    private func checkIdleState() {
        guard let anyEvent = CGEventType(rawValue: ~0) else { return }
        let idleSec = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
        let nowIdle = idleSec >= idleTimeout
        
        if nowIdle != self.isUserIdle {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.isUserIdle = nowIdle
            }
            updatePausedState()
        }
    }
    
    /// Called immediately when mouse or keyboard interaction is detected
    public func userDidInteract() {
        if self.isUserIdle {
            withAnimation(.easeInOut(duration: 0.8)) {
                self.isUserIdle = false
            }
            updatePausedState()
        }
    }
    
    private func updatePausedState() {
        let shouldPause = !isScreenAwake || isUserIdle
        if shouldPause != isAnimationPaused {
            self.isAnimationPaused = shouldPause
        }
    }
}
