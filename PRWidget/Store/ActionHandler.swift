import Foundation
import TelemetryDeck

@MainActor
final class ActionHandler {
    private let client = GitHubGraphQLClient.shared

    func approve(pr: PullRequest, comment: String?, token: String, endpoint: URL) async throws {
        try await submitReview(pr: pr, event: "APPROVE", comment: comment, token: token, endpoint: endpoint, signal: "prApproved")
    }

    func requestChanges(pr: PullRequest, comment: String, token: String, endpoint: URL) async throws {
        try await submitReview(pr: pr, event: "REQUEST_CHANGES", comment: comment, token: token, endpoint: endpoint, signal: "prChangesRequested")
    }

    private func submitReview(pr: PullRequest, event: String, comment: String?, token: String, endpoint: URL, signal: String) async throws {
        NSLog("[PArr] Submitting %@ on PR #%d (%@)", event, pr.number, pr.repository.nameWithOwner)
        var variables: [String: Any] = ["pullRequestId": pr.id, "event": event]
        if let comment, !comment.isEmpty { variables["body"] = comment }

        let _: AddReviewResponse = try await client.execute(
            query: GitHubMutations.addPullRequestReview,
            variables: variables,
            token: token,
            endpoint: endpoint
        )
        NSLog("[PArr] ✓ %@ on PR #%d", event, pr.number)
        TelemetryDeck.signal(signal)
    }

    func merge(pr: PullRequest, method: MergeMethod, token: String, endpoint: URL) async throws {
        NSLog("[PArr] Merging PR #%d (%@) via %@", pr.number, pr.repository.nameWithOwner, method.rawValue)
        let variables: [String: Any] = [
            "pullRequestId": pr.id,
            "mergeMethod": method.rawValue,
        ]

        let _: MergePRResponse = try await client.execute(
            query: GitHubMutations.mergePullRequest,
            variables: variables,
            token: token,
            endpoint: endpoint
        )
        NSLog("[PArr] ✓ Merged PR #%d via %@", pr.number, method.rawValue)
        TelemetryDeck.signal("prMerged", parameters: ["method": method.rawValue])
    }

    func addLabel(to pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
        NSLog("[PArr] Adding label to PR #%d (%@)", pr.number, pr.repository.nameWithOwner)
        let variables: [String: Any] = [
            "labelableId": pr.id,
            "labelIds": [labelNodeId],
        ]

        let response: AddLabelsResponse = try await client.execute(
            query: GitHubMutations.addLabelsToLabelable,
            variables: variables,
            token: token,
            endpoint: endpoint
        )

        let labels = response.addLabelsToLabelable.labelable.labels.nodes.map {
            PRLabel(nodeId: $0.id, name: $0.name, color: $0.color, description: $0.description)
        }
        NSLog("[PArr] ✓ Label added to PR #%d — now %d label(s)", pr.number, labels.count)
        return labels
    }

    func removeLabel(from pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
        NSLog("[PArr] Removing label from PR #%d (%@)", pr.number, pr.repository.nameWithOwner)
        let variables: [String: Any] = [
            "labelableId": pr.id,
            "labelIds": [labelNodeId],
        ]

        let response: RemoveLabelsResponse = try await client.execute(
            query: GitHubMutations.removeLabelsFromLabelable,
            variables: variables,
            token: token,
            endpoint: endpoint
        )

        let labels = response.removeLabelsFromLabelable.labelable.labels.nodes.map {
            PRLabel(nodeId: $0.id, name: $0.name, color: $0.color, description: $0.description)
        }
        NSLog("[PArr] ✓ Label removed from PR #%d — now %d label(s)", pr.number, labels.count)
        return labels
    }

    /// Remove then re-add a label to re-trigger GitHub hooks
    func recycleLabel(on pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
        NSLog("[PArr] Recycling label on PR #%d to re-trigger hooks", pr.number)
        _ = try await removeLabel(from: pr, labelNodeId: labelNodeId, token: token, endpoint: endpoint)
        return try await addLabel(to: pr, labelNodeId: labelNodeId, token: token, endpoint: endpoint)
    }
}
