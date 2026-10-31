import Foundation
import AppKit
import Combine

public final class NotchManager: ObservableObject {
    public static let shared = NotchManager()
    
    @Published public private(set) var currentGeometry: NotchGeometry = .fallback
    @Published public private(set) var targetScreen: NSScreen?
    @Published public private(set) var detectedDeviceName: String = "Detecting Display..."
    
    private var screenChangeObserver: Any?
    
    private init() {
        self.targetScreen = NSScreen.main
        updateGeometry()
        
        // Listen for screen resolution / connection changes
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateGeometry()
        }
        
        NotificationCenter.default.addObserver(
            forName: .notchGeometryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateGeometry()
        }
    }
    
    deinit {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    public func updateGeometry() {
        // Find best candidate screen: screen with physical notch first, or primary display
        let screen = findNotchedScreen() ?? NSScreen.main ?? NSScreen.screens.first
        self.targetScreen = screen
        
        guard let screen = screen else {
            self.currentGeometry = .fallback
            self.detectedDeviceName = "Standard Display"
            return
        }
        
        let settings = NotchSettings.shared
        let hasPhysicalNotch = checkPhysicalNotch(on: screen)
        
        // Identify model name for user convenience
        self.detectedDeviceName = identifyDevice(for: screen, hasNotch: hasPhysicalNotch)
        
        switch settings.preset {
        case .auto:
            if hasPhysicalNotch,
               let tl = screen.auxiliaryTopLeftArea,
               let tr = screen.auxiliaryTopRightArea,
               tl.width > 0, tr.width > 0 {
                let notchWidth = tr.minX - tl.maxX
                let notchHeight = screen.frame.maxY - tl.minY
                let notchCenterX = (tl.maxX + tr.minX) / 2
                
                self.currentGeometry = NotchGeometry(
                    width: notchWidth,
                    height: max(notchHeight, screen.safeAreaInsets.top),
                    centerX: notchCenterX,
                    topY: screen.frame.maxY,
                    cornerRadius: 10,
                    hasPhysicalNotch: true,
                    isFloating: false
                )
            } else if screen.safeAreaInsets.top > 0 {
                // Secondary fallback for notch detection
                self.currentGeometry = NotchGeometry(
                    width: 185,
                    height: screen.safeAreaInsets.top,
                    centerX: screen.frame.midX,
                    topY: screen.frame.maxY,
                    cornerRadius: 10,
                    hasPhysicalNotch: true,
                    isFloating: false
                )
            } else {
                // Non-notch screen: use floating Dynamic Island pill
                self.currentGeometry = NotchGeometry(
                    width: 160,
                    height: 32,
                    centerX: screen.frame.midX,
                    topY: screen.frame.maxY - 8,
                    cornerRadius: 16,
                    hasPhysicalNotch: false,
                    isFloating: true
                )
            }
            
        case .mbp14:
            self.currentGeometry = NotchGeometry(
                width: 178,
                height: 32,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY,
                cornerRadius: 10,
                hasPhysicalNotch: true,
                isFloating: false
            )
            
        case .mbp16:
            self.currentGeometry = NotchGeometry(
                width: 185,
                height: 32,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY,
                cornerRadius: 10,
                hasPhysicalNotch: true,
                isFloating: false
            )
            
        case .mba13:
            self.currentGeometry = NotchGeometry(
                width: 178,
                height: 32,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY,
                cornerRadius: 10,
                hasPhysicalNotch: true,
                isFloating: false
            )
            
        case .mba15:
            self.currentGeometry = NotchGeometry(
                width: 178,
                height: 32,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY,
                cornerRadius: 10,
                hasPhysicalNotch: true,
                isFloating: false
            )
            
        case .dynamicIsland:
            self.currentGeometry = NotchGeometry(
                width: 170,
                height: 32,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY - 10,
                cornerRadius: 16,
                hasPhysicalNotch: false,
                isFloating: true
            )
            
        case .custom:
            self.currentGeometry = NotchGeometry(
                width: settings.customWidth,
                height: settings.customHeight,
                centerX: screen.frame.midX,
                topY: screen.frame.maxY + settings.customYOffset,
                cornerRadius: settings.customCornerRadius,
                hasPhysicalNotch: hasPhysicalNotch,
                isFloating: !hasPhysicalNotch
            )
        }
    }
    
    private func findNotchedScreen() -> NSScreen? {
        for screen in NSScreen.screens {
            if checkPhysicalNotch(on: screen) {
                return screen
            }
        }
        return nil
    }
    
    private func checkPhysicalNotch(on screen: NSScreen) -> Bool {
        if screen.safeAreaInsets.top > 0 {
            return true
        }
        if let tl = screen.auxiliaryTopLeftArea, let tr = screen.auxiliaryTopRightArea, tl.width > 0, tr.width > 0 {
            return true
        }
        return false
    }
    
    private func identifyDevice(for screen: NSScreen, hasNotch: Bool) -> String {
        guard hasNotch else {
            return "External / Non-Notch Display (\(Int(screen.frame.width))x\(Int(screen.frame.height)))"
        }
        
        let width = screen.frame.width
        let height = screen.frame.height
        
        // Approximate point resolutions on MacBook displays
        if width >= 1700 && height >= 1080 {
            return "MacBook Pro 16\" (Liquid Retina XDR)"
        } else if width >= 1500 && height >= 950 {
            return "MacBook Pro 14\" (Liquid Retina XDR)"
        } else if width >= 1650 {
            return "MacBook Air 15.3\" (Liquid Retina)"
        } else if width >= 1280 && width <= 1500 {
            return "MacBook Air 13.6\" (Liquid Retina)"
        } else {
            return "Apple Silicon MacBook with Notch"
        }
    }
}

