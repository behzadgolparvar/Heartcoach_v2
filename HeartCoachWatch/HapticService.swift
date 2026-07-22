import WatchKit
import HeartRateCoachCore

final class HapticService {

    func play(_ pattern: HapticPattern) {
        let type: WKHapticType
        switch pattern {
        case .short:            type = .directedUp         // HR below zone — go faster
        case .long:             type = .directedDown        // HR above zone — slow down
        case .doubleTap:        type = .success             // 30s in-zone positive feedback
        case .emergencyRepeated: type = .notification       // emergency — fires on every tick
        }
        WKInterfaceDevice.current().play(type)
    }
}
