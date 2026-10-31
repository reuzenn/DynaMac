import SwiftUI
import AppKit

// MARK: - Geometry

/// Single source of truth for island sizes, shared by the SwiftUI view and the window controller
/// (which uses it to decide where the panel accepts mouse events).
enum IslandLayout {
    /// Fixed transparent panel. It never resizes, so springs always animate from the
    /// live on-screen value and stay fully interruptible.
    static let panelSize = CGSize(width: 720, height: 320)

    static func earWidth(_ activity: NotchTab) -> CGFloat {
        activity == .timer ? 54 : 36
    }

    static func hudEarWidth(_ hud: HUDType) -> CGFloat {
        if case .power = hud { return 92 }
        return 64
    }

    static func expandedSize(_ tab: NotchTab) -> CGSize {
        switch tab {
        case .media:   return CGSize(width: 490, height: 215)
        case .timer:   return CGSize(width: 490, height: 180)
        case .shelf:   return CGSize(width: 490, height: 185)
        case .battery: return CGSize(width: 490, height: 155)
        }
    }

    static func droppingSize(_ g: NotchGeometry) -> CGSize {
        CGSize(width: g.width + 220, height: 100)
    }

    static func dropZoneSize(_ g: NotchGeometry) -> CGSize {
        CGSize(width: g.width + 320, height: 150)
    }

    static func size(state: NotchPresentationState,
                     compact: NotchTab?,
                     hovering: Bool,
                     stretch: CGFloat,
                     geometry g: NotchGeometry) -> CGSize {
        var s: CGSize
        switch state {
        case .collapsed:
            s = CGSize(width: g.width + (compact.map { 2 * earWidth($0) } ?? 0), height: g.height)
            if hovering {
                // Hint: the island swells slightly toward the pointer before committing.
                s.width += 16
                s.height += 4
            }
        case .hud(let hud):
            let hudHeight: CGFloat = g.hasPhysicalNotch ? (g.height + 28) : 56
            let extraWidth: CGFloat
            switch hud {
            case .power: extraWidth = 110
            case .volume, .brightness: extraWidth = 84
            }
            s = CGSize(width: max(g.width + extraWidth, 290), height: hudHeight)
        case .dropping:
            s = droppingSize(g)
        case .expanded(let tab):
            s = expandedSize(tab)
        }

        // Live 1:1 stretch from scroll / drag gestures (already rubber-banded).
        if stretch > 0 {
            s.height += stretch
            s.width += stretch * 0.5
        } else if stretch < 0 {
            s.height = max(g.height, s.height + stretch)
            s.width = max(g.width, s.width + stretch * 0.3)
        }
        return s
    }

    static func bottomRadius(state: NotchPresentationState, compact: NotchTab?, geometry g: NotchGeometry) -> CGFloat {
        switch state {
        case .collapsed: return compact == nil ? min(g.cornerRadius, g.height / 2) : 14
        case .hud:       return 18
        case .dropping:  return 26
        case .expanded:  return 30
        }
    }
}

// MARK: - Motion

/// Spring vocabulary (Apple "damping + response" model).
/// Critically damped by default; bounce only where the gesture carried momentum.
enum IslandMotion {
    static var reduceMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

    private static let reduced = Animation.easeInOut(duration: 0.2)

    /// Tap-to-expand: iPhone island has a subtle, physical overshoot.
    static var expand: Animation { reduceMotion ? reduced : .spring(response: 0.42, dampingFraction: 0.8) }
    /// Retract: no bounce, settles calmly into the notch.
    static var collapse: Animation { reduceMotion ? reduced : .spring(response: 0.38, dampingFraction: 1.0) }
    /// After a flick/scroll release — momentum justifies bounce.
    static var momentum: Animation { reduceMotion ? reduced : .spring(response: 0.4, dampingFraction: 0.76) }
    static var hud: Animation { reduceMotion ? reduced : .spring(response: 0.34, dampingFraction: 0.86) }
    static var hover: Animation { reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 1.0) }
    static var press: Animation { .spring(response: 0.18, dampingFraction: 1.0) }

    static func content(_ reduce: Bool) -> AnyTransition {
        reduce ? .opacity : .materialize
    }
}

/// "Materialize, don't just fade": content arrives with blur + scale + opacity together.
struct MaterializeModifier: ViewModifier {
    let blur: CGFloat
    let opacity: Double
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: blur)
            .opacity(opacity)
            .scaleEffect(scale, anchor: .top)
    }
}

extension AnyTransition {
    static var materialize: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: MaterializeModifier(blur: 10, opacity: 0, scale: 0.88),
                identity: MaterializeModifier(blur: 0, opacity: 1, scale: 1)
            ),
            removal: .modifier(
                active: MaterializeModifier(blur: 8, opacity: 0, scale: 0.94),
                identity: MaterializeModifier(blur: 0, opacity: 1, scale: 1)
            ).animation(.easeOut(duration: 0.14))
        )
    }
}

// MARK: - Gesture physics

/// Progressive resistance past a boundary — the further you pull, the less it follows.
func rubberband(_ offset: CGFloat, dimension: CGFloat, constant: CGFloat = 0.55) -> CGFloat {
    (offset * dimension * constant) / (dimension + constant * abs(offset))
}

/// Apple's momentum projection (Designing Fluid Interfaces). Velocity in pt/s.
func projectMomentum(_ velocity: CGFloat, decelerationRate: CGFloat = 0.99) -> CGFloat {
    (velocity / 1000) * decelerationRate / (1 - decelerationRate)
}

