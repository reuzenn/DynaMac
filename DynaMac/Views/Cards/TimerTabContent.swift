import SwiftUI

public struct TimerTabContent: View {
    @ObservedObject var timerService = TimerService.shared
    @ObservedObject var l10n = LocalizationManager.shared
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Circular progress and time
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 5)
                        .frame(width: 58, height: 58)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(timerService.progress))
                        .stroke(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)
                        .animation(.linear(duration: 0.5), value: timerService.progress)
                    
                    Text(timerService.formattedTime)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(timerService.isRunning ? l10n.t("timer_in_progress") : l10n.t("timer_focus"))
                        .font(.system(size: 12, weight: .bold))
                        .tracking(-0.2)
                        .foregroundColor(.white)
                    
                    // Preset pills
                    HStack(spacing: 6) {
                        presetButton("5m", minutes: 5)
                        presetButton("15m", minutes: 15)
                        presetButton("25m", minutes: 25)
                        presetButton("45m", minutes: 45)
                    }
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 8) {
                    Button(action: {
                        HapticService.play(.tap)
                        timerService.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(timerService.isRunning ? Color.orange : Color.green)
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: timerService.isRunning ? 0 : 1)
                        }
                    }
                    .buttonStyle(.fluidPress(scale: 0.90))
                    
                    Button(action: {
                        HapticService.play(.snap)
                        timerService.reset()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.fluidPress)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    private func presetButton(_ label: String, minutes: Int) -> some View {
        Button(action: {
            HapticService.play(.tap)
            timerService.setPreset(minutes: minutes)
        }) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(timerService.totalSeconds == minutes * 60 ? Color.orange.opacity(0.4) : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.fluidPress)
    }
}

