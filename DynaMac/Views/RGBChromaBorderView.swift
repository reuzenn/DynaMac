import AppKit
import SwiftUI
import QuartzCore

/// Pure GPU-accelerated RGB rainbow border running entirely inside Core Animation / WindowServer
/// Consumes 0.0% CPU by completely bypassing main-thread timer loops
public struct RGBChromaBorderView: NSViewRepresentable {
    public var bottomRadius: CGFloat
    public var isFloating: Bool
    public var duration: Double
    public var isPaused: Bool
    
    public init(bottomRadius: CGFloat, isFloating: Bool, duration: Double, isPaused: Bool) {
        self.bottomRadius = bottomRadius
        self.isFloating = isFloating
        self.duration = duration
        self.isPaused = isPaused
    }
    
    public func makeNSView(context: Context) -> RGBChromaNSView {
        let view = RGBChromaNSView()
        view.update(bottomRadius: bottomRadius, isFloating: isFloating, duration: duration, isPaused: isPaused)
        return view
    }
    
    public func updateNSView(_ nsView: RGBChromaNSView, context: Context) {
        nsView.update(bottomRadius: bottomRadius, isFloating: isFloating, duration: duration, isPaused: isPaused)
    }
}

public final class RGBChromaNSView: NSView {
    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CAShapeLayer()
    
    private var currentBottomRadius: CGFloat = -1
    private var currentIsFloating: Bool = false
    private var currentDuration: Double = 0
    private var isCurrentlyPaused: Bool = false
    
    public override init(frame: NSRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        wantsLayer = true
        layer?.masksToBounds = false
        
        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        let colors: [NSColor] = [
            .systemRed, .systemOrange, .systemYellow,
            .systemGreen, .systemCyan, .systemBlue,
            .systemPurple, .systemPink, .systemRed
        ]
        gradientLayer.colors = colors.map { $0.cgColor }
        
        maskLayer.fillColor = NSColor.clear.cgColor
        maskLayer.strokeColor = NSColor.white.cgColor
        maskLayer.lineWidth = 2.5
        
        layer?.addSublayer(gradientLayer)
        layer?.mask = maskLayer
    }
    
    public func update(bottomRadius: CGFloat, isFloating: Bool, duration: Double, isPaused: Bool) {
        let geometryChanged = (currentBottomRadius != bottomRadius || currentIsFloating != isFloating)
        let durationChanged = (currentDuration != duration)
        let pausedChanged = (isCurrentlyPaused != isPaused)
        
        self.currentBottomRadius = bottomRadius
        self.currentIsFloating = isFloating
        self.currentDuration = max(0.5, duration)
        self.isCurrentlyPaused = isPaused
        
        if geometryChanged {
            updateMaskGeometry()
        }
        
        if durationChanged || pausedChanged {
            updateAnimationState()
        }
    }
    
    public override func layout() {
        super.layout()
        updateMaskGeometry()
        updateGradientBounds()
    }
    
    private func updateGradientBounds() {
        let b = bounds
        guard b.width > 0 && b.height > 0 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Use diagonal dimension to ensure full rotation without clipping corners
        let dim = sqrt(b.width * b.width + b.height * b.height) * 1.2
        gradientLayer.bounds = CGRect(x: 0, y: 0, width: dim, height: dim)
        gradientLayer.position = CGPoint(x: b.midX, y: b.midY)
        
        CATransaction.commit()
    }
    
    private func updateMaskGeometry() {
        let b = bounds
        guard b.width > 0 && b.height > 0 else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let shape = DynamicIslandShape(bottomCornerRadius: currentBottomRadius, isFloating: currentIsFloating)
        let path = shape.path(in: b).cgPath
        
        maskLayer.frame = b
        maskLayer.path = path
        
        CATransaction.commit()
    }
    
    private func updateAnimationState() {
        if isCurrentlyPaused {
            gradientLayer.removeAnimation(forKey: "rgbSpinAnimation")
        } else {
            if gradientLayer.animation(forKey: "rgbSpinAnimation") == nil {
                let anim = CABasicAnimation(keyPath: "transform.rotation.z")
                anim.fromValue = 0
                anim.toValue = Double.pi * 2
                anim.duration = currentDuration
                anim.repeatCount = .infinity
                anim.isRemovedOnCompletion = false
                gradientLayer.add(anim, forKey: "rgbSpinAnimation")
            }
        }
    }
}
