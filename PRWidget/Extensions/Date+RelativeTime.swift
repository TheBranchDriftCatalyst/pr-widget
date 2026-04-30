import Foundation

extension Date {
    var relativeTimeString: String {
        let interval = Date.now.timeIntervalSince(self)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }

    /// Branch-appropriate relative time: "3 days ago", "2 months ago", or date if > 1 year.
    var branchRelativeTimeString: String {
        let interval = Date.now.timeIntervalSince(self)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min\(minutes == 1 ? "" : "s") ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }
        let days = hours / 24
        if days < 30 { return "\(days) day\(days == 1 ? "" : "s") ago" }
        let months = days / 30
        if months < 12 { return "\(months) month\(months == 1 ? "" : "s") ago" }
        return self.formatted(date: .abbreviated, time: .omitted)
    }
}
