import Foundation
import WatchKit

enum LaundryHapticEvent {
    case start
    case pause
    case resume
    case completion
    case snoozeAccepted
}

struct HapticsClient: HapticsPlaying {
    func play(_ event: LaundryHapticEvent) {
        let type: WKHapticType
        switch event {
        case .start:
            type = .click
        case .pause:
            type = .directionDown
        case .resume:
            type = .directionUp
        case .completion:
            type = .notification
        case .snoozeAccepted:
            type = .success
        }
        WKInterfaceDevice.current().play(type)
    }
}

struct NoopHapticsClient: HapticsPlaying {
    func play(_ event: LaundryHapticEvent) {}
}
