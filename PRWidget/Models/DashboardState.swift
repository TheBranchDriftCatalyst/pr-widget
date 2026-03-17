import Foundation

enum PRCategory: String, CaseIterable, Sendable {
    case needsAction = "Needs Your Action"
    case readyToShip = "Ready to Ship"
    case waitingOnOthers = "Waiting on Others"
}

struct DashboardState: Sendable {
    var pullRequests: [PullRequest] = []
    var currentUser: String = ""
    var lastRefreshed: Date?
    var isLoading: Bool = false
    var error: String?

    // Cached category arrays — updated via categorize(currentUser:)
    private(set) var needsAction: [PullRequest] = []
    private(set) var readyToShip: [PullRequest] = []
    private(set) var waitingOnOthers: [PullRequest] = []

    /// Recomputes the three triage categories. Call whenever `pullRequests` or `currentUser` changes.
    mutating func categorize() {
        let currentUser = self.currentUser

        needsAction = pullRequests.filter { pr in
            let reviewRequested = pr.reviewRequests.contains { $0.login == currentUser }
            let changesRequested = pr.author.login == currentUser && pr.reviewDecision == .changesRequested
            let ciFailing = pr.author.login == currentUser && (pr.statusCheckRollup == .failure || pr.statusCheckRollup == .error)
            let hasConflicts = pr.author.login == currentUser && pr.mergeable == .conflicting
            return reviewRequested || changesRequested || ciFailing || hasConflicts
        }
        .sorted { $0.urgencyScore > $1.urgencyScore }

        readyToShip = pullRequests.filter { pr in
            pr.author.login == currentUser
            && pr.reviewDecision == .approved
            && pr.statusCheckRollup == .success
            && pr.mergeable == .mergeable
            && !pr.isDraft
        }
        .sorted { $0.updatedAt > $1.updatedAt }

        let actionIDs = Set(needsAction.map(\.id))
        let readyIDs = Set(readyToShip.map(\.id))
        waitingOnOthers = pullRequests.filter { pr in
            pr.author.login == currentUser
            && !actionIDs.contains(pr.id)
            && !readyIDs.contains(pr.id)
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    var blockedByMeCount: Int {
        pullRequests.filter { pr in
            pr.reviewRequests.contains { $0.login == currentUser }
            && pr.reviews.allSatisfy { $0.author.login != currentUser || $0.state == .pending }
        }.count
    }

    var ownedByMeCount: Int {
        pullRequests.filter { $0.author.login == currentUser }.count
    }

    var readyToShipCount: Int {
        readyToShip.count
    }

    var isEmpty: Bool { pullRequests.isEmpty }
}
