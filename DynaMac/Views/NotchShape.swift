import SwiftUI

/// Clean Dynamic Island shape with flat top edge (glued to MacBook bezel) and continuous rounded bottom corners
public struct DynamicIslandShape: Shape {
    public var bottomCornerRadius: CGFloat
    public var isFloating: Bool
    public var topCornerRadius: CGFloat
    
    public init(bottomCornerRadius: CGFloat = 14, isFloating: Bool = false, topCornerRadius: CGFloat = 0) {
        self.bottomCornerRadius = bottomCornerRadius
        self.isFloating = isFloating
        self.topCornerRadius = isFloating ? bottomCornerRadius : 0
    }
    
    public var animatableData: CGFloat {
        get { bottomCornerRadius }
        set { bottomCornerRadius = newValue }
    }
    
    public func path(in rect: CGRect) -> Path {
        // Extend 3pt into the top bezel on physical notch screens to guarantee zero gap / zero crookedness
        let bleed: CGFloat = isFloating ? 0 : 3
        let drawRect = CGRect(
            x: rect.minX,
            y: rect.minY - bleed,
            width: rect.width,
            height: rect.height + bleed
        )
        
        return UnevenRoundedRectangle(
            topLeadingRadius: isFloating ? topCornerRadius : 0,
            bottomLeadingRadius: bottomCornerRadius,
            bottomTrailingRadius: bottomCornerRadius,
            topTrailingRadius: isFloating ? topCornerRadius : 0,
            style: .continuous
        ).path(in: drawRect)
    }
}
