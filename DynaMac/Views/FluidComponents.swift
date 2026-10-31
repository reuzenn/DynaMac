import SwiftUI

/// Tactile button style responding on pointer-down with instant scale & subtle dimming
public struct FluidPressButtonStyle: ButtonStyle {
    public var scaleAmount: CGFloat
    public var hapticOnPress: Bool
    
    public init(scaleAmount: CGFloat = 0.94, hapticOnPress: Bool = true) {
        self.scaleAmount = scaleAmount
        self.hapticOnPress = hapticOnPress
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && hapticOnPress {
                    HapticService.play(.tap)
                }
            }
    }
}

public extension ButtonStyle where Self == FluidPressButtonStyle {
    static var fluidPress: FluidPressButtonStyle { FluidPressButtonStyle() }
    static func fluidPress(scale: CGFloat = 0.94) -> FluidPressButtonStyle { FluidPressButtonStyle(scaleAmount: scale) }
}

/// GPU-accelerated animated audio spectrum equalizer with zero main-thread CPU overhead
public struct EqualizerView: View {
    public let barCount: Int
    public let isPlaying: Bool
    public var color: Color
    public var gradient: LinearGradient?
    public var width: CGFloat
    public var minHeight: CGFloat
    public var maxHeight: CGFloat
    
    public init(
        barCount: Int = 5,
        isPlaying: Bool,
        color: Color = .pink,
        gradient: LinearGradient? = nil,
        width: CGFloat = 3,
        minHeight: CGFloat = 3,
        maxHeight: CGFloat = 20
    ) {
        self.barCount = barCount
        self.isPlaying = isPlaying
        self.color = color
        self.gradient = gradient
        self.width = width
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { idx in
                EqualizerBar(
                    isPlaying: isPlaying,
                    color: color,
                    gradient: gradient,
                    width: width,
                    minHeight: minHeight,
                    maxHeight: maxHeight,
                    duration: 0.32 + Double((idx * 7) % 5) * 0.08,
                    delay: Double(idx) * 0.06
                )
            }
        }
    }
}

private struct EqualizerBar: View {
    let isPlaying: Bool
    let color: Color
    let gradient: LinearGradient?
    let width: CGFloat
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let duration: Double
    let delay: Double
    
    @State private var isElevated: Bool = false
    
    var body: some View {
        Group {
            if let gradient = gradient {
                RoundedRectangle(cornerRadius: width / 2)
                    .fill(gradient)
            } else {
                RoundedRectangle(cornerRadius: width / 2)
                    .fill(isPlaying ? color : Color.white.opacity(0.2))
            }
        }
        .frame(width: width, height: isPlaying && isElevated ? maxHeight : minHeight)
        .animation(
            isPlaying
                ? Animation.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)
                : Animation.easeOut(duration: 0.2),
            value: isElevated
        )
        .onAppear {
            if isPlaying {
                isElevated = true
            }
        }
        .onChange(of: isPlaying) { _, playing in
            isElevated = playing
        }
    }
}

