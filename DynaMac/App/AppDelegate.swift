import Foundation
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as an accessory app (menu bar + notch overlay, no dock icon clutter)
        NSApp.setActivationPolicy(.accessory)
        
        // Start Notch Manager & Window Controller
        NotchManager.shared.updateGeometry()
        NotchWindowController.shared.start()
        
        // Setup Menu Bar Item
        StatusBarController.shared.setup()
        
        print("DynaMac initialized successfully for: \(NotchManager.shared.detectedDeviceName)")
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}

