import Foundation

enum PRFilter: String, CaseIterable, Sendable {
    case all = "All"
    case needsAction = "Needs Action"
    case readyToShip = "Ready to Ship"
    case waitingOnOthers = "Waiting"
    case myPRs = "My PRs"
    case reviewRequested = "Review Requested"
    case mentioned = "Mentioned"
    case blockedByMe = "Blocked by Me"

    /// Whether this filter is a triage category (shown in primary row)
    var isTriage: Bool {
        switch self {
        case .all, .needsAction, .readyToShip, .waitingOnOthers:
            return true
        default:
            return false
        }
    }

    /// Whether this filter is a perspective filter (shown in secondary row)
    var isPerspective: Bool {
        !isTriage
    }

    static var triageFilters: [PRFilter] {
        allCases.filter(\.isTriage)
    }

    static var perspectiveFilters: [PRFilter] {
        allCases.filter(\.isPerspective)
    }
}
