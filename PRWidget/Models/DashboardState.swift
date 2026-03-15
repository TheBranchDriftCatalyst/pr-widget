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

    var needsAction: [PullRequest] {
        pullRequests.filter { pr in
            // Reviews requested on the current user
            let reviewRequested = pr.reviewRequests.contains { $0.login == currentUser }
            // Changes requested on user's own PRs
            let changesRequested = pr.author.login == currentUser && pr.reviewDecision == .changesRequested
            // CI failures on user's PRs
            let ciFailing = pr.author.login == currentUser && (pr.statusCheckRollup == .failure || pr.statusCheckRollup == .error)
            // Merge conflicts on user's PRs
            let hasConflicts = pr.author.login == currentUser && pr.mergeable == .conflicting

            return reviewRequested || changesRequested || ciFailing || hasConflicts
        }
        .sorted { $0.urgencyScore > $1.urgencyScore }
    }

    var readyToShip: [PullRequest] {
        pullRequests.filter { pr in
            pr.author.login == currentUser
            && pr.reviewDecision == .approved
            && pr.statusCheckRollup == .success
            && pr.mergeable == .mergeable
            && !pr.isDraft
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    }

    var waitingOnOthers: [PullRequest] {
        let actionIDs = Set(needsAction.map(\.id))
        let readyIDs = Set(readyToShip.map(\.id))
        return pullRequests.filter { pr in
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
