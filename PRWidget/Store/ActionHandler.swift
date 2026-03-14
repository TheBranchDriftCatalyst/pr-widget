import Foundation

@MainActor
final class ActionHandler {
    private let client = GitHubGraphQLClient()

    func approve(pr: PullRequest, comment: String?, token: String, endpoint: URL) async throws {
        var variables: [String: Any] = [
            "pullRequestId": pr.id,
            "event": "APPROVE",
        ]
        if let comment, !comment.isEmpty {
            variables["body"] = comment
        }

        let _: AddReviewResponse = try await client.execute(
            query: GitHubMutations.addPullRequestReview,
            variables: variables,
            token: token,
            endpoint: endpoint
        )
    }

    func requestChanges(pr: PullRequest, comment: String, token: String, endpoint: URL) async throws {
        let variables: [String: Any] = [
            "pullRequestId": pr.id,
            "event": "REQUEST_CHANGES",
            "body": comment,
        ]

        let _: AddReviewResponse = try await client.execute(
            query: GitHubMutations.addPullRequestReview,
            variables: variables,
            token: token,
            endpoint: endpoint
        )
    }

    func merge(pr: PullRequest, method: MergeMethod, token: String, endpoint: URL) async throws {
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
    }

    func addLabel(to pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
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

        return response.addLabelsToLabelable.labelable.labels.nodes.map {
            PRLabel(nodeId: $0.id, name: $0.name, color: $0.color, description: $0.description)
        }
    }

    func removeLabel(from pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
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

        return response.removeLabelsFromLabelable.labelable.labels.nodes.map {
            PRLabel(nodeId: $0.id, name: $0.name, color: $0.color, description: $0.description)
        }
    }

    /// Remove then re-add a label to re-trigger GitHub hooks
    func recycleLabel(on pr: PullRequest, labelNodeId: String, token: String, endpoint: URL) async throws -> [PRLabel] {
        _ = try await removeLabel(from: pr, labelNodeId: labelNodeId, token: token, endpoint: endpoint)
        return try await addLabel(to: pr, labelNodeId: labelNodeId, token: token, endpoint: endpoint)
    }
}
