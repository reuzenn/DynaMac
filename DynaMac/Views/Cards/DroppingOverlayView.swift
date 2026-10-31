import SwiftUI

public struct DroppingOverlayView: View {
    @ObservedObject var l10n = LocalizationManager.shared
    @ObservedObject var notchManager = NotchManager.shared
    @State private var isAnimating: Bool = false
    
    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.cyan)
                .offset(y: isAnimating ? -2 : 2)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            Text(l10n.t("drop_files_title"))
                .font(.system(size: 12, weight: .bold))
                .tracking(-0.2)
                .foregroundColor(.white)
            
            Text(l10n.t("drop_files_sub"))
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, notchManager.currentGeometry.height)
        .padding(.bottom, 8)
        .onAppear {
            isAnimating = true
        }
    }
}
