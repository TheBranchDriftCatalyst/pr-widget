import Foundation

enum GitHubMutations {
    static let addPullRequestReview = """
    mutation AddReview($pullRequestId: ID!, $event: PullRequestReviewEvent!, $body: String) {
        addPullRequestReview(input: {pullRequestId: $pullRequestId, event: $event, body: $body}) {
            pullRequestReview {
                id
                state
            }
        }
    }
    """

    static let mergePullRequest = """
    mutation MergePR($pullRequestId: ID!, $mergeMethod: PullRequestMergeMethod!) {
        mergePullRequest(input: {pullRequestId: $pullRequestId, mergeMethod: $mergeMethod}) {
            pullRequest {
                id
                state
                merged
            }
        }
    }
    """

    static let addLabelsToLabelable = """
    mutation AddLabels($labelableId: ID!, $labelIds: [ID!]!) {
        addLabelsToLabelable(input: {labelableId: $labelableId, labelIds: $labelIds}) {
            labelable {
                ... on PullRequest {
                    id
                    labels(first: 10) {
                        nodes {
                            id
                            name
                            color
                            description
                        }
                    }
                }
            }
        }
    }
    """

    static let removeLabelsFromLabelable = """
    mutation RemoveLabels($labelableId: ID!, $labelIds: [ID!]!) {
        removeLabelsFromLabelable(input: {labelableId: $labelableId, labelIds: $labelIds}) {
            labelable {
                ... on PullRequest {
                    id
                    labels(first: 10) {
                        nodes {
                            id
                            name
                            color
                            description
                        }
                    }
                }
            }
        }
    }
    """

    static let addReviewThreadReply = """
    mutation AddReviewThreadReply($threadId: ID!, $body: String!) {
        addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $threadId, body: $body}) {
            comment {
                id
                author { login avatarUrl }
                body
                createdAt
            }
        }
    }
    """
}
