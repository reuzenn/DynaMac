import Foundation
import IOKit.ps
import Combine

public final class BatteryService: ObservableObject {
    public static let shared = BatteryService()
    
    @Published public private(set) var percentage: Int = 100
    @Published public private(set) var isCharging: Bool = false
    @Published public private(set) var isACConnected: Bool = false
    @Published public private(set) var timeRemainingMinutes: Int? = nil
    
    public var onPowerSourcePluggedIn: ((Int) -> Void)?
    
    private var runLoopSource: CFRunLoopSource?
    private var lastACConnected: Bool?
    
    private init() {
        updateBatteryInfo()
        registerPowerSourceNotification()
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    private func registerPowerSourceNotification() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let loopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let service = Unmanaged<BatteryService>.fromOpaque(context).takeUnretainedValue()
            service.updateBatteryInfo()
        }, context)?.takeRetainedValue()
        
        if let source = loopSource {
            self.runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }
    
    public func updateBatteryInfo() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            let curCap = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 100
            let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int ?? 100
            let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
            let powerState = desc[kIOPSPowerSourceStateKey as String] as? String ?? ""
            let isAC = (powerState == (kIOPSACPowerValue as String))
            let timeToEmpty = desc[kIOPSTimeToEmptyKey as String] as? Int
            
            let calcPercentage = maxCap > 0 ? Int((Double(curCap) / Double(maxCap)) * 100) : 100
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Detect plugged in event transition
                if let lastAC = self.lastACConnected, !lastAC, isAC {
                    self.onPowerSourcePluggedIn?(calcPercentage)
                }
                self.lastACConnected = isAC
                
                self.percentage = calcPercentage
                self.isCharging = isCharging
                self.isACConnected = isAC
                self.timeRemainingMinutes = (timeToEmpty != nil && timeToEmpty! > 0) ? timeToEmpty : nil
            }
            break
        }
    }
}

