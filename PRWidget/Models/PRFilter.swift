import Foundation

enum PRFilter: String, CaseIterable, Sendable {
    case all = "All"
    case myPRs = "My PRs"
    case reviewRequested = "Review Requested"
    case mentioned = "Mentioned"
    case blockedByMe = "Blocked by Me"
}
