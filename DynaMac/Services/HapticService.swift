import AppKit

public enum HapticFeedbackType {
    case tap
    case snap
    case levelChange
}

public struct HapticService {
    public static func play(_ type: HapticFeedbackType = .tap) {
        // Only trigger if enabled by user in Settings
        guard NotchSettings.shared.isHapticsEnabled else { return }
        
        let performer = NSHapticFeedbackManager.defaultPerformer
        switch type {
        case .tap:
            performer.perform(.generic, performanceTime: .now)
        case .snap:
            performer.perform(.alignment, performanceTime: .now)
        case .levelChange:
            performer.perform(.levelChange, performanceTime: .now)
        }
    }
}
