import SwiftUI

public struct BatteryTabContent: View {
    @ObservedObject var batteryService = BatteryService.shared
    @ObservedObject var notchManager = NotchManager.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    public var body: some View {
        HStack(spacing: 16) {
            // Battery Gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 5)
                    .frame(width: 58, height: 58)
                
                Circle()
                    .trim(from: 0, to: CGFloat(batteryService.percentage) / 100.0)
                    .stroke(
                        batteryService.percentage > 20 ? (batteryService.isCharging ? Color.green : Color.cyan) : Color.red,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 58, height: 58)
                
                VStack(spacing: 0) {
                    if batteryService.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Text("\(batteryService.percentage)%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(batteryService.isCharging ? l10n.t("battery_charging") : (batteryService.isACConnected ? l10n.t("battery_full_ac") : l10n.t("battery_on_battery")))
                    .font(.system(size: 12, weight: .bold))
                    .tracking(-0.2)
                    .foregroundColor(.white)
                
                Text(notchManager.detectedDeviceName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                if let mins = batteryService.timeRemainingMinutes, !batteryService.isACConnected {
                    Text(String(format: l10n.t("battery_remaining"), mins / 60, mins % 60))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                } else if batteryService.isCharging {
                    Text(l10n.t("fast_charging"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green.opacity(0.85))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Label(batteryService.isACConnected ? l10n.t("ac_connected") : l10n.t("on_battery"), systemImage: batteryService.isACConnected ? "powerplug.fill" : "battery.100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(batteryService.isACConnected ? .green : .cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

