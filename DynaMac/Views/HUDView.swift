import SwiftUI

public struct HUDView: View {
    public let hud: HUDType
    @ObservedObject var l10n = LocalizationManager.shared
    @ObservedObject var notchManager = NotchManager.shared
    
    private var geom: NotchGeometry {
        notchManager.currentGeometry
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if geom.hasPhysicalNotch {
                // Top spacer covers the physical notch hardware (camera bezel)
                Spacer()
                    .frame(height: geom.height)
            }
            
            // HUD content row placed completely below the hardware notch!
            HStack(spacing: 12) {
                switch hud {
                case .volume(let value, let isMuted):
                    Image(systemName: isMuted ? "speaker.slash.fill" : (value > 0.6 ? "speaker.wave.3.fill" : (value > 0.2 ? "speaker.wave.2.fill" : "speaker.wave.1.fill")))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isMuted ? .red : .white)
                        .frame(width: 18)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(0, min(geo.size.width * CGFloat(value), geo.size.width)), height: 6)
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(height: 6)
                    
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 34, alignment: .trailing)
                    
                case .brightness(let value):
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow)
                        .frame(width: 18)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(Color.yellow)
                                .frame(width: max(0, min(geo.size.width * CGFloat(value), geo.size.width)), height: 6)
                        }
                        .frame(height: geo.size.height)
                    }
                    .frame(height: 6)
                    
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 34, alignment: .trailing)
                    
                case .power(let isCharging, let percentage):
                    Image(systemName: isCharging ? "bolt.fill" : "battery.100")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.green)
                        .frame(width: 18)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(isCharging ? l10n.t("magsafe_connected") : l10n.t("battery_status"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(String(format: l10n.t("charged"), percentage))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2.5)
                            .frame(width: 18, height: 18)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(percentage) / 100.0)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity)
        }
    }
}
