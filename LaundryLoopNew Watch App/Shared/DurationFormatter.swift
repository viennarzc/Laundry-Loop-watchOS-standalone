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

    static func elapsedString(since date: Date, now: Date = .now) -> String {
        let elapsed = max(now.timeIntervalSince(date), 0)

        if elapsed < 60 {
            return "just now"
        }

        let minutes = Int(elapsed / 60)
        if minutes < 60 {
            return "\(minutes) min ago"
        }

        let hours = Int(elapsed / 3600)
        if hours < 24 {
            return hours == 1 ? "1 hr ago" : "\(hours) hr ago"
        }

        let days = Int(elapsed / 86_400)
        return days == 1 ? "1 day ago" : "\(days) days ago"
    }
}
