import Foundation

enum DurationFormatter {
    static func minutesString(seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let secondsPart = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsPart)
    }

    static func shortLabel(minutes: Int) -> String {
        "\(minutes)m"
    }

    static func clockString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
