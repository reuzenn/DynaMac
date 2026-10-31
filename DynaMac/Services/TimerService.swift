import Foundation
import AppKit
import Combine

public final class TimerService: ObservableObject {
    public static let shared = TimerService()
    
    @Published public private(set) var totalSeconds: Int = 1500 // 25 min default
    @Published public private(set) var remainingSeconds: Int = 1500
    @Published public private(set) var isRunning: Bool = false
    
    private var timer: Timer?
    
    public var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    public var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
    
    private init() {}
    
    public func setPreset(minutes: Int) {
        pause()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
    }
    
    public func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    public func start() {
        guard !isRunning else { return }
        if remainingSeconds <= 0 {
            remainingSeconds = totalSeconds
        }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
            } else {
                self.complete()
            }
        }
    }
    
    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    public func reset() {
        pause()
        remainingSeconds = totalSeconds
    }
    
    private func complete() {
        pause()
        NSSound(named: "Glass")?.play()
    }
}

