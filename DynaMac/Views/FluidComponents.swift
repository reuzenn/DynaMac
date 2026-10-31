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
            .onChange(of: configuration.isPressed) { pressed in
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

