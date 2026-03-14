import Foundation

enum AlgorithmicSynopsis {
    static func generate(for pr: PullRequest, detail: PRDetail) -> AISynopsis {
        var summaryParts: [String] = []
        var actionItems: [String] = []
        var urgencyReason: String?

        // Size analysis
        let size = pr.linesChanged
        let sizeDesc = if size > 1000 { "large" }
            else if size > 500 { "medium-sized" }
            else if size > 100 { "moderate" }
            else { "small" }

        summaryParts.append("\(sizeDesc) PR (\(pr.additions)+/\(pr.deletions)-, \(detail.changedFiles) files)")

        // Age analysis
        let hours = Int(pr.age / 3600)
        if hours > 120 {
            summaryParts.append("open for \(hours / 24) days")
            urgencyReason = "This PR has been open for over 5 days"
        } else if hours > 48 {
            summaryParts.append("open for \(hours / 24) days")
        }

        // Review state
        switch pr.reviewDecision {
        case .approved:
            summaryParts.append("approved")
        case .changesRequested:
            summaryParts.append("changes requested")
            actionItems.append("Address review feedback")
        case .reviewRequired:
            summaryParts.append("awaiting review")
            actionItems.append("Needs code review")
        case nil:
            if pr.reviewRequests.isEmpty {
                actionItems.append("No reviewers assigned")
            } else {
                actionItems.append("Waiting for \(pr.reviewRequests.map(\.login).joined(separator: ", ")) to review")
            }
        }

        // CI status
        switch pr.statusCheckRollup {
        case .failure:
            actionItems.append("CI checks are failing")
            if urgencyReason == nil { urgencyReason = "CI pipeline is failing" }
        case .error:
            actionItems.append("CI encountered an error")
        case .pending:
            summaryParts.append("CI running")
        case .success:
            break
        case .unknown:
            break
        }

        // Merge state
        if pr.mergeable == .conflicting {
            actionItems.append("Resolve merge conflicts")
            if urgencyReason == nil { urgencyReason = "Merge conflicts detected" }
        }

        if pr.isDraft {
            summaryParts.append("draft")
            actionItems.append("Mark as ready for review when complete")
        }

        // Ready to merge check
        if pr.reviewDecision == .approved
            && pr.statusCheckRollup == .success
            && pr.mergeable == .mergeable
            && !pr.isDraft {
            actionItems.insert("Ready to merge", at: 0)
        }

        // Comment activity
        let commentCount = detail.comments.count
        if commentCount > 10 {
            summaryParts.append("active discussion (\(commentCount) comments)")
        } else if commentCount > 0 {
            summaryParts.append("\(commentCount) comment\(commentCount == 1 ? "" : "s")")
        }

        let summary = summaryParts.joined(separator: " · ").prefix(1).uppercased() + summaryParts.joined(separator: " · ").dropFirst()

        return AISynopsis(
            summary: String(summary),
            actionItems: actionItems,
            urgencyReason: urgencyReason,
            generatedAt: .now,
            provider: .algorithmic
        )
    }
}
