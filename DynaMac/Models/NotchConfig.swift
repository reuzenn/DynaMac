import Foundation
import AppKit
import Combine

/// Model presets for MacBook notch hardware across all Apple Silicon generations (M1 to M6+)
public enum MacBookNotchPreset: String, CaseIterable, Identifiable, Codable {
    case auto = "Auto Detect (Recommended)"
    case mbp14 = "MacBook Pro 14\" (M1–M6)"
    case mbp16 = "MacBook Pro 16\" (M1–M6)"
    case mba13 = "MacBook Air 13.6\" (M2–M6)"
    case mba15 = "MacBook Air 15.3\" (M2–M6)"
    case dynamicIsland = "Dynamic Island (Floating Pill)"
    case custom = "Custom Calibration"
    
    public var id: String { rawValue }
    
    /// Default hardware dimensions for each known model in logical points
    public var defaultDimensions: (width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
        switch self {
        case .auto:
            return (185, 32, 10)
        case .mbp14:
            return (178, 32, 10)
        case .mbp16:
            return (185, 32, 10)
        case .mba13:
            return (178, 32, 10)
        case .mba15:
            return (178, 32, 10)
        case .dynamicIsland:
            return (160, 32, 16)
        case .custom:
            return (185, 32, 10)
        }
    }
}

/// Dynamic Notch geometry calculated for the target screen
public struct NotchGeometry: Equatable {
    public var width: CGFloat
    public var height: CGFloat
    public var centerX: CGFloat
    public var topY: CGFloat
    public var cornerRadius: CGFloat
    public var hasPhysicalNotch: Bool
    public var isFloating: Bool
    
    public static let fallback = NotchGeometry(
        width: 185,
        height: 32,
        centerX: 800,
        topY: 1000,
        cornerRadius: 10,
        hasPhysicalNotch: true,
        isFloating: false
    )
}

/// User configuration and persistent preferences
public final class NotchSettings: ObservableObject {
    public static let shared = NotchSettings()
    
    @Published public var preset: MacBookNotchPreset {
        didSet {
            UserDefaults.standard.set(preset.rawValue, forKey: "notch_preset")
            NotificationCenter.default.post(name: .notchGeometryDidChange, object: nil)
        }
    }
    
    @Published public var customWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(customWidth), forKey: "notch_customWidth") }
    }
    
    @Published public var customHeight: CGFloat {
        didSet { UserDefaults.standard.set(Double(customHeight), forKey: "notch_customHeight") }
    }
    
    @Published public var customCornerRadius: CGFloat {
        didSet { UserDefaults.standard.set(Double(customCornerRadius), forKey: "notch_customCornerRadius") }
    }
    
    @Published public var customYOffset: CGFloat {
        didSet { UserDefaults.standard.set(Double(customYOffset), forKey: "notch_customYOffset") }
    }
    
    // Feature Toggles
    @Published public var isHoverToExpandEnabled: Bool {
        didSet { UserDefaults.standard.set(isHoverToExpandEnabled, forKey: "feat_hover") }
    }
    
    @Published public var isClickToExpandEnabled: Bool {
        didSet { UserDefaults.standard.set(isClickToExpandEnabled, forKey: "feat_click") }
    }
    
    @Published public var isMediaWidgetEnabled: Bool {
        didSet { UserDefaults.standard.set(isMediaWidgetEnabled, forKey: "feat_media") }
    }
    
    @Published public var isDropShelfEnabled: Bool {
        didSet { UserDefaults.standard.set(isDropShelfEnabled, forKey: "feat_shelf") }
    }
    
    @Published public var isVolumeHUDEnabled: Bool {
        didSet { UserDefaults.standard.set(isVolumeHUDEnabled, forKey: "feat_vol_hud") }
    }
    
    @Published public var isBatteryAlertsEnabled: Bool {
        didSet { UserDefaults.standard.set(isBatteryAlertsEnabled, forKey: "feat_battery") }
    }
    
    @Published public var isFocusTimerEnabled: Bool {
        didSet { UserDefaults.standard.set(isFocusTimerEnabled, forKey: "feat_timer") }
    }
    
    @Published public var showCollapsedEars: Bool {
        didSet { UserDefaults.standard.set(showCollapsedEars, forKey: "feat_ears") }
    }
    
    @Published public var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: "feat_haptics") }
    }
    
    @Published public var showCalibrationOverlay: Bool = false
    
    @Published public var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: "launch_at_login") }
    }
    
    private init() {
        let savedPreset = UserDefaults.standard.string(forKey: "notch_preset") ?? MacBookNotchPreset.auto.rawValue
        self.preset = MacBookNotchPreset(rawValue: savedPreset) ?? .auto
        
        self.customWidth = CGFloat(UserDefaults.standard.double(forKey: "notch_customWidth") > 0 ? UserDefaults.standard.double(forKey: "notch_customWidth") : 185)
        self.customHeight = CGFloat(UserDefaults.standard.double(forKey: "notch_customHeight") > 0 ? UserDefaults.standard.double(forKey: "notch_customHeight") : 32)
        self.customCornerRadius = CGFloat(UserDefaults.standard.double(forKey: "notch_customCornerRadius") > 0 ? UserDefaults.standard.double(forKey: "notch_customCornerRadius") : 10)
        self.customYOffset = CGFloat(UserDefaults.standard.double(forKey: "notch_customYOffset"))
        
        self.isHoverToExpandEnabled = UserDefaults.standard.object(forKey: "feat_hover") == nil ? false : UserDefaults.standard.bool(forKey: "feat_hover")
        self.isClickToExpandEnabled = UserDefaults.standard.object(forKey: "feat_click") == nil ? true : UserDefaults.standard.bool(forKey: "feat_click")
        self.isMediaWidgetEnabled = UserDefaults.standard.object(forKey: "feat_media") == nil ? true : UserDefaults.standard.bool(forKey: "feat_media")
        self.isDropShelfEnabled = UserDefaults.standard.object(forKey: "feat_shelf") == nil ? true : UserDefaults.standard.bool(forKey: "feat_shelf")
        self.isVolumeHUDEnabled = UserDefaults.standard.object(forKey: "feat_vol_hud") == nil ? true : UserDefaults.standard.bool(forKey: "feat_vol_hud")
        self.isBatteryAlertsEnabled = UserDefaults.standard.object(forKey: "feat_battery") == nil ? true : UserDefaults.standard.bool(forKey: "feat_battery")
        self.isFocusTimerEnabled = UserDefaults.standard.object(forKey: "feat_timer") == nil ? true : UserDefaults.standard.bool(forKey: "feat_timer")
        self.showCollapsedEars = UserDefaults.standard.object(forKey: "feat_ears") == nil ? true : UserDefaults.standard.bool(forKey: "feat_ears")
        self.isHapticsEnabled = UserDefaults.standard.bool(forKey: "feat_haptics") // Defaults to false (off)
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launch_at_login")
    }
}

extension Notification.Name {
    public static let notchGeometryDidChange = Notification.Name("dynaMac.notchGeometryDidChange")
    public static let requestNotchExpand = Notification.Name("dynaMac.requestNotchExpand")
    public static let requestNotchCollapse = Notification.Name("dynaMac.requestNotchCollapse")
}

