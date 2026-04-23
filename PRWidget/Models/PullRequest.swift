import Foundation

struct TaskProgress: Sendable, Hashable {
    let completed: Int
    let total: Int
}

struct PullRequest: Identifiable, Sendable {
    let id: String
    let number: Int
    let title: String
    let url: URL
    let state: PRState
    let isDraft: Bool
    let createdAt: Date
    let updatedAt: Date
    let author: PRUser
    let repository: PRRepository
    let headRefName: String
    let baseRefName: String
    let additions: Int
    let deletions: Int
    let mergeable: MergeableState
    let reviewDecision: ReviewDecision?
    let statusCheckRollup: CIStatus
    let reviews: [PRReview]
    var labels: [PRLabel]
    let assignees: [PRUser]
    let reviewRequests: [PRUser]
    let commentCount: Int
    let taskProgress: TaskProgress?
    var detail: PRDetail?
    /// The UUID of the GitHubAccount that fetched this PR (for multi-account support).
    var sourceAccountID: UUID?

    var repoNameWithOwner: String { repository.nameWithOwner }

    var linesChanged: Int { additions + deletions }

    var age: TimeInterval { Date.now.timeIntervalSince(createdAt) }

    var lastActivityAge: TimeInterval { Date.now.timeIntervalSince(updatedAt) }

    var ageText: String {
        let hours = Int(age / 3600)
        if hours < 1 { return "<1h" }
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }

    var urgencyScore: Double {
        var score = 0.0

        // Time-based urgency
        let hours = age / 3600
        if hours > 120 { score += 5.0 }
        else if hours > 48 { score += 3.0 }
        else if hours > 24 { score += 1.5 }

        // Review state
        switch reviewDecision {
        case .changesRequested: score += 4.0
        case .reviewRequired: score += 2.0
        case .approved: score -= 1.0
        case nil: score += 1.0
        }

        // CI status
        switch statusCheckRollup {
        case .failure, .error: score += 3.0
        case .pending: score += 1.0
        case .success: break
        case .unknown: score += 0.5
        }

        // Merge conflicts
        if mergeable == .conflicting { score += 3.0 }

        // Size penalty for large PRs
        if linesChanged > 1000 { score += 1.0 }
        else if linesChanged > 500 { score += 0.5 }

        return score
    }
}

extension PullRequest: Hashable {
    static func == (lhs: PullRequest, rhs: PullRequest) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(updatedAt)
    }
}
