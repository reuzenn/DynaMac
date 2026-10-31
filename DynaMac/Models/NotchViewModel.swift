import Foundation
import SwiftUI
import AppKit
import Combine

public final class NotchViewModel: ObservableObject {
    public static let shared = NotchViewModel()
    
    @Published public var state: NotchPresentationState = .collapsed
    @Published public var activeTab: NotchTab = .media
    @Published public var isHovering: Bool = false
    @Published public var isDropTargeted: Bool = false
    @Published public var stretch: CGFloat = 0
    @Published public var isPressed: Bool = false
    @Published public var isFileDragActive: Bool = false
    
    // Spatial ordering: Left of notch (media, shelf) -> Right of notch (timer, battery)
    public let availableTabs: [NotchTab] = [.media, .shelf, .timer, .battery]
    
    public let settings = NotchSettings.shared
    public let notchManager = NotchManager.shared
    public let mediaService = MediaService.shared
    public let batteryService = BatteryService.shared
    public let audioService = AudioService.shared
    public let shelfService = ShelfService.shared
    public let timerService = TimerService.shared
    
    private var hudDismissTimer: Timer?
    private var hoverDebounceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Trackpad gesture state
    private var accumulatedScrollX: CGFloat = 0
    private var swipeLocked: Bool = false
    private var lastSwitchTime: Date = .distantPast
    
    /// Dynamic Island compact activity indicator (leading/trailing ears when resting in notch)
    public var compactActivity: NotchTab? {
        guard settings.showCollapsedEars else { return nil }
        if timerService.isRunning { return .timer }
        if mediaService.isPlaying { return .media }
        if !shelfService.items.isEmpty { return .shelf }
        if batteryService.isCharging || batteryService.percentage <= 20 { return .battery }
        return nil
    }
    
    private init() {
        setupHooks()
    }
    
    private func setupHooks() {
        // Observe live services so compact activity and island size update immediately
        mediaService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        shelfService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        timerService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        batteryService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Battery plugged in hook
        batteryService.onPowerSourcePluggedIn = { [weak self] percentage in
            guard let self = self, self.settings.isBatteryAlertsEnabled else { return }
            self.showHUD(.power(isCharging: true, percentage: percentage))
        }
        
        // Volume change hook
        audioService.onVolumeChanged = { [weak self] volume, isMuted in
            guard let self = self, self.settings.isVolumeHUDEnabled else { return }
            // Do not interrupt expanded live activities or active file drops
            if case .expanded = self.state { return }
            if case .dropping = self.state { return }
            self.showHUD(.volume(value: volume, isMuted: isMuted))
        }
        
        // Notification Center expand/collapse requests
        NotificationCenter.default.addObserver(
            forName: .requestNotchExpand,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.expand()
        }
        
        NotificationCenter.default.addObserver(
            forName: .requestNotchCollapse,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.collapse()
        }
    }
    
    public func showHUD(_ hud: HUDType) {
        hudDismissTimer?.invalidate()
        withAnimation(IslandMotion.hud) {
            self.state = .hud(hud)
        }
        
        hudDismissTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if case .hud = self.state {
                self.collapse()
            }
        }
    }
    
    public func expand(to tab: NotchTab? = nil) {
        hudDismissTimer?.invalidate()
        self.stretch = 0
        
        if let tab = tab {
            self.activeTab = tab
        } else if let compact = self.compactActivity {
            self.activeTab = compact
        } else if mediaService.isPlaying {
            self.activeTab = .media
        } else if !shelfService.items.isEmpty {
            self.activeTab = .shelf
        } else if timerService.isRunning {
            self.activeTab = .timer
        } else {
            self.activeTab = .media
        }
        
        withAnimation(IslandMotion.expand) {
            self.state = .expanded(self.activeTab)
        }
    }
    
    public func collapse() {
        hudDismissTimer?.invalidate()
        hoverDebounceTimer?.invalidate()
        self.stretch = 0
        self.isHovering = false
        self.accumulatedScrollX = 0
        self.swipeLocked = false
        
        withAnimation(IslandMotion.collapse) {
            self.state = .collapsed
        }
    }
    
    public func toggleExpandCollapse() {
        if state.isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    public func selectTab(_ tab: NotchTab) {
        guard activeTab != tab else { return }
        HapticService.play(.tap)
        withAnimation(IslandMotion.expand) {
            self.activeTab = tab
            self.state = .expanded(tab)
        }
    }
    
    public func nextTab() {
        guard let idx = availableTabs.firstIndex(of: activeTab) else { return }
        let nextIdx = (idx + 1) % availableTabs.count
        selectTab(availableTabs[nextIdx])
    }
    
    public func previousTab() {
        guard let idx = availableTabs.firstIndex(of: activeTab) else { return }
        let prevIdx = (idx - 1 + availableTabs.count) % availableTabs.count
        selectTab(availableTabs[prevIdx])
    }
    
    // MARK: - Trackpad Gesture Handling
    public func handleScroll(event: NSEvent) {
        let deltaX = event.scrollingDeltaX
        let deltaY = event.scrollingDeltaY
        let phase = event.phase
        let momentum = event.momentumPhase
        
        // Ignore momentum events so inertial scrolling does not trigger phantom tab changes
        guard momentum.isEmpty else { return }
        
        if state.isExpanded {
            // Trackpad 2-finger horizontal swipe
            if !phase.isEmpty {
                if phase == .began {
                    accumulatedScrollX = 0
                    swipeLocked = false
                } else if phase == .changed {
                    accumulatedScrollX += deltaX
                    
                    let threshold: CGFloat = 26
                    let now = Date()
                    
                    if !swipeLocked && now.timeIntervalSince(lastSwitchTime) > 0.22 {
                        if accumulatedScrollX < -threshold {
                            // Swiped left -> move to next tab on the right
                            nextTab()
                            lastSwitchTime = now
                            swipeLocked = true
                        } else if accumulatedScrollX > threshold {
                            // Swiped right -> move to previous tab on the left
                            previousTab()
                            lastSwitchTime = now
                            swipeLocked = true
                        }
                    }
                } else if phase == .ended || phase == .cancelled {
                    accumulatedScrollX = 0
                    swipeLocked = false
                }
            } else {
                // Non-gesture mouse wheel or legacy continuous scroll
                let now = Date()
                if now.timeIntervalSince(lastSwitchTime) > 0.35 && abs(deltaX) > 10 {
                    if deltaX < 0 {
                        nextTab()
                    } else {
                        previousTab()
                    }
                    lastSwitchTime = now
                }
            }
            
            // Swipe UP gesture to collapse island
            if deltaY > 28 && phase == .changed && abs(deltaY) > abs(deltaX) * 1.5 {
                collapse()
            }
        } else if state == .collapsed {
            // Pull down gesture with live rubber-banding
            if phase == .changed || phase == .began {
                if deltaY < 0 {
                    let liveDelta = abs(deltaY) * 1.5
                    self.stretch = rubberband(liveDelta, dimension: 160)
                }
            } else if phase == .ended {
                if stretch > 35 {
                    HapticService.play(.tap)
                    expand()
                } else {
                    withAnimation(IslandMotion.collapse) {
                        self.stretch = 0
                    }
                }
            }
        }
    }
    
    // MARK: - Hover Logic
    public func handleHoverChanged(_ hovering: Bool) {
        guard settings.isHoverToExpandEnabled else { return }
        if NSEvent.pressedMouseButtons != 0 { return }
        
        self.isHovering = hovering
        hoverDebounceTimer?.invalidate()
        
        if hovering {
            // Dwell timer (0.35s) so crossing cursor doesn't trigger accidental expansion
            hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                guard let self = self, self.isHovering else { return }
                guard NSEvent.pressedMouseButtons == 0 else { return }
                if self.state == .collapsed {
                    self.expand()
                }
            }
        } else {
            hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
                guard let self = self, !self.isHovering else { return }
                if case .expanded = self.state {
                    self.collapse()
                }
            }
        }
    }
    
    // MARK: - Drop Logic
    public func handleDropTargetChanged(_ targeted: Bool) {
        guard settings.isDropShelfEnabled else { return }
        self.isDropTargeted = targeted
        
        if targeted {
            withAnimation(IslandMotion.expand) {
                self.state = .dropping
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, !self.isDropTargeted else { return }
                if case .dropping = self.state {
                    self.collapse()
                }
            }
        }
    }
    
    public func handleFilesDropped(_ urls: [URL]) {
        shelfService.addFiles(urls: urls)
        expand(to: .shelf)
    }
}
