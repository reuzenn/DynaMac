import Foundation
import SwiftUI

/// A live activity the island can present (iPhone "Live Activity" equivalent).
public enum NotchTab: String, CaseIterable, Identifiable {
    case media
    case timer
    case shelf
    case battery

    public var id: String { rawValue }
}

public enum HUDType: Equatable {
    case volume(value: Float, isMuted: Bool)
    case brightness(value: Float)
    case power(isCharging: Bool, percentage: Int)
}

/// Island presentation, mirroring iPhone Dynamic Island:
/// - `collapsed`: rests inside the notch, or shows a compact live activity (leading + trailing ears)
/// - `hud`: transient system feedback (volume, charging) in the compact shape
/// - `expanded`: full live activity
/// - `dropping`: file drag hovering over the island
public enum NotchPresentationState: Equatable {
    case collapsed
    case hud(HUDType)
    case expanded(NotchTab)
    case dropping

    public var isExpanded: Bool {
        if case .expanded = self { return true }
        return false
    }

    public var isHUD: Bool {
        if case .hud = self { return true }
        return false
    }
}
