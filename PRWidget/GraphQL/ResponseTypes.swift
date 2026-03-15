import Foundation

// MARK: - Dashboard Response

struct DashboardResponse: Decodable {
    let viewer: ViewerResponse
    let authored: SearchResponse
    let reviewRequested: SearchResponse
}

struct ViewerResponse: Decodable {
    let login: String
    let avatarUrl: String?
}

struct SearchResponse: Decodable {
    let nodes: [PRNode?]
}

struct PRNode: Decodable {
    let id: String
    let number: Int
    let title: String
    let url: String
    let state: String
    let isDraft: Bool
    let createdAt: String
    let updatedAt: String
    let additions: Int
    let deletions: Int
    let mergeable: String
    let reviewDecision: String?
    let headRefName: String
    let baseRefName: String
    let author: UserNode?
    let repository: RepositoryNode
    let commits: CommitsConnection
    let reviews: ReviewsConnection
    let labels: LabelsConnection
    let assignees: UsersConnection
    let reviewRequests: ReviewRequestsConnection
}

struct UserNode: Decodable {
    let login: String
    let avatarUrl: String?
}

struct RepositoryNode: Decodable {
    let nameWithOwner: String
    let url: String
}

struct CommitsConnection: Decodable {
    let nodes: [CommitNode]
}

struct CommitNode: Decodable {
    let commit: CommitDetail
}

struct CommitDetail: Decodable {
    let statusCheckRollup: StatusCheckRollup?
}

struct StatusCheckRollup: Decodable {
    let state: String
}

struct ReviewsConnection: Decodable {
    let nodes: [ReviewNode]
}

struct ReviewNode: Decodable {
    let id: String
    let state: String
    let submittedAt: String?
    let author: UserNode?
}

struct LabelsConnection: Decodable {
    let nodes: [LabelNode]
}

struct LabelNode: Decodable {
    let id: String
    let name: String
    let color: String
    let description: String?
}

struct UsersConnection: Decodable {
    let nodes: [UserNode]
}

struct ReviewRequestsConnection: Decodable {
    let nodes: [ReviewRequestNode]
}

struct ReviewRequestNode: Decodable {
    let requestedReviewer: UserNode?
}

// MARK: - PR Detail Response

struct PRDetailResponse: Decodable {
    let node: PRDetailNode
}

struct PRDetailNode: Decodable {
    let bodyText: String?
    let comments: PRCommentsConnection
    let timelineItems: TimelineItemsConnection
    let commits: DetailCommitsConnection
    let changedFiles: Int
    let files: FilesConnection?
    let reviewThreads: ReviewThreadsConnection?
}

struct PRCommentsConnection: Decodable {
    let nodes: [CommentNode]
}

struct CommentNode: Decodable {
    let id: String
    let author: UserNode?
    let body: String
    let createdAt: String
    let url: String?
    let isMinimized: Bool
}

struct TimelineItemsConnection: Decodable {
    let nodes: [TimelineItemNode]
}

struct TimelineItemNode: Decodable {
    let __typename: String
    let id: String?
    let author: UserNode?
    let actor: UserNode?
    let state: String?
    let createdAt: String?
    let label: TimelineLabelNode?
    let assignee: TimelineAssigneeNode?

    enum CodingKeys: String, CodingKey {
        case __typename, id, author, actor, state, createdAt, label, assignee
    }
}

struct TimelineLabelNode: Decodable {
    let name: String
}

struct TimelineAssigneeNode: Decodable {
    let login: String?
}

struct DetailCommitsConnection: Decodable {
    let nodes: [DetailCommitNode]
}

struct DetailCommitNode: Decodable {
    let commit: DetailCommitInfo
}

struct DetailCommitInfo: Decodable {
    let oid: String
    let message: String
    let url: String?
    let author: CommitAuthorNode?
    let statusCheckRollup: DetailStatusCheckRollup?
}

struct CommitAuthorNode: Decodable {
    let user: UserNode?
}

struct DetailStatusCheckRollup: Decodable {
    let contexts: CheckRunContextsConnection?
}

struct CheckRunContextsConnection: Decodable {
    let nodes: [CheckRunNode]
}

struct CheckRunNode: Decodable {
    let id: String?
    let name: String?
    let status: String?
    let conclusion: String?
    let detailsUrl: String?
}

// MARK: - File & Review Thread Response Types

struct FilesConnection: Decodable {
    let nodes: [FileNode]
}

struct FileNode: Decodable {
    let path: String
    let additions: Int
    let deletions: Int
    let changeType: String
}

struct ReviewThreadsConnection: Decodable {
    let nodes: [ReviewThreadNode]
}

struct ReviewThreadNode: Decodable {
    let id: String
    let isResolved: Bool
    let isOutdated: Bool
    let path: String
    let line: Int?
    let startLine: Int?
    let diffSide: String?
    let comments: ReviewThreadCommentsConnection
}

struct ReviewThreadCommentsConnection: Decodable {
    let nodes: [ReviewThreadCommentNode]
}

struct ReviewThreadCommentNode: Decodable {
    let id: String
    let author: UserNode?
    let body: String
    let createdAt: String
    let url: String?
}

// MARK: - Detail Mapping

extension PRDetailNode {
    func toPRDetail() -> PRDetail {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        func parseDate(_ str: String) -> Date {
            dateFormatter.date(from: str) ?? fallbackFormatter.date(from: str) ?? .now
        }

        let mappedComments = comments.nodes.map { node in
            PRComment(
                id: node.id,
                author: PRUser(login: node.author?.login ?? "ghost", avatarURL: node.author?.avatarUrl.flatMap(URL.init)),
                body: node.body,
                createdAt: parseDate(node.createdAt),
                url: node.url.flatMap(URL.init),
                isMinimized: node.isMinimized
            )
        }

        let mappedTimeline: [PRTimelineEvent] = timelineItems.nodes.compactMap { node in
            guard let id = node.id, let createdAtStr = node.createdAt else { return nil }
            let actorUser = node.actor ?? node.author
            let actor = actorUser.map { PRUser(login: $0.login, avatarURL: $0.avatarUrl.flatMap(URL.init)) }
            let actorName = actor?.login ?? "Someone"

            let type: PRTimelineEventType
            let desc: String
            switch node.__typename {
            case "PullRequestReview":
                type = .reviewed
                desc = "\(actorName) \(node.state?.lowercased() ?? "reviewed")"
            case "IssueComment":
                type = .commented
                desc = "\(actorName) commented"
            case "MergedEvent":
                type = .merged
                desc = "\(actorName) merged this PR"
            case "ClosedEvent":
                type = .closed
                desc = "\(actorName) closed this PR"
            case "ReopenedEvent":
                type = .reopened
                desc = "\(actorName) reopened this PR"
            case "LabeledEvent":
                type = .labeled
                desc = "\(actorName) added label \(node.label?.name ?? "")"
            case "AssignedEvent":
                type = .assigned
                desc = "\(actorName) assigned \(node.assignee?.login ?? "someone")"
            case "MentionedEvent":
                type = .mentioned
                desc = "\(actorName) was mentioned"
            case "HeadRefForcePushedEvent":
                type = .headRefForcePushed
                desc = "\(actorName) force-pushed"
            default:
                return nil
            }

            return PRTimelineEvent(
                id: id,
                type: type,
                actor: actor,
                createdAt: parseDate(createdAtStr),
                description: desc
            )
        }

        let mappedCommits = commits.nodes.map { node in
            PRCommit(
                id: node.commit.oid,
                sha: String(node.commit.oid.prefix(7)),
                message: node.commit.message,
                author: node.commit.author?.user.map { PRUser(login: $0.login, avatarURL: $0.avatarUrl.flatMap(URL.init)) },
                url: node.commit.url.flatMap(URL.init)
            )
        }

        let checkRuns: [PRCheckRun] = commits.nodes.last?.commit.statusCheckRollup?.contexts?.nodes.compactMap { node in
            guard let id = node.id, let name = node.name else { return nil }
            return PRCheckRun(
                id: id,
                name: name,
                status: node.status ?? "UNKNOWN",
                conclusion: node.conclusion,
                url: node.detailsUrl.flatMap(URL.init)
            )
        } ?? []

        let mappedReviewThreads: [PRReviewThread] = reviewThreads?.nodes.map { node in
            PRReviewThread(
                id: node.id,
                path: node.path,
                line: node.line,
                startLine: node.startLine,
                diffSide: node.diffSide.flatMap { DiffSide(rawValue: $0) } ?? .RIGHT,
                isResolved: node.isResolved,
                isOutdated: node.isOutdated,
                comments: node.comments.nodes.map { comment in
                    PRReviewComment(
                        id: comment.id,
                        author: PRUser(login: comment.author?.login ?? "ghost", avatarURL: comment.author?.avatarUrl.flatMap(URL.init)),
                        body: comment.body,
                        createdAt: parseDate(comment.createdAt),
                        url: comment.url.flatMap(URL.init)
                    )
                }
            )
        } ?? []

        return PRDetail(
            comments: mappedComments,
            timelineEvents: mappedTimeline,
            commits: mappedCommits,
            checkRuns: checkRuns,
            changedFiles: changedFiles,
            bodyText: bodyText ?? "",
            reviewThreads: mappedReviewThreads
        )
    }
}

// MARK: - Verify Viewer

struct VerifyViewerResponse: Decodable {
    let viewer: ViewerResponse
}

// MARK: - Mutation Responses

struct AddReviewResponse: Decodable {
    let addPullRequestReview: AddReviewPayload
}

struct AddReviewPayload: Decodable {
    let pullRequestReview: ReviewResult
}

struct ReviewResult: Decodable {
    let id: String
    let state: String
}

struct MergePRResponse: Decodable {
    let mergePullRequest: MergePRPayload
}

struct MergePRPayload: Decodable {
    let pullRequest: MergeResult
}

struct MergeResult: Decodable {
    let id: String
    let state: String
    let merged: Bool
}

struct AddLabelsResponse: Decodable {
    let addLabelsToLabelable: AddLabelsPayload
}

struct AddLabelsPayload: Decodable {
    let labelable: LabelableResult
}

struct LabelableResult: Decodable {
    let id: String
    let labels: LabelsConnection
}

struct RemoveLabelsResponse: Decodable {
    let removeLabelsFromLabelable: RemoveLabelsPayload
}

struct RemoveLabelsPayload: Decodable {
    let labelable: LabelableResult
}

// MARK: - Review Thread Reply Response

struct AddReviewThreadReplyResponse: Decodable {
    let addPullRequestReviewThreadReply: AddReviewThreadReplyPayload
}

struct AddReviewThreadReplyPayload: Decodable {
    let comment: ReviewThreadCommentNode
}

// MARK: - Mapping to Domain Models

extension PRNode {
    func toPullRequest() -> PullRequest? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        func parseDate(_ str: String) -> Date {
            dateFormatter.date(from: str) ?? fallbackFormatter.date(from: str) ?? .now
        }

        guard let prURL = URL(string: url),
              let repoURL = URL(string: repository.url) else {
            return nil
        }

        let ciState: CIStatus
        if let rollup = commits.nodes.first?.commit.statusCheckRollup?.state {
            ciState = CIStatus(rawValue: rollup) ?? .unknown
        } else {
            ciState = .unknown
        }

        // Deduplicate reviews: keep latest per author
        let latestReviews: [PRReview] = {
            var byAuthor: [String: ReviewNode] = [:]
            for node in reviews.nodes {
                guard let authorLogin = node.author?.login else { continue }
                if let existing = byAuthor[authorLogin] {
                    let existingDate = existing.submittedAt.flatMap { parseDate($0) } ?? .distantPast
                    let nodeDate = node.submittedAt.flatMap { parseDate($0) } ?? .distantPast
                    if nodeDate > existingDate {
                        byAuthor[authorLogin] = node
                    }
                } else {
                    byAuthor[authorLogin] = node
                }
            }
            return byAuthor.values.map { node in
                PRReview(
                    id: node.id,
                    author: PRUser(login: node.author?.login ?? "", avatarURL: node.author?.avatarUrl.flatMap(URL.init)),
                    state: ReviewState(rawValue: node.state) ?? .pending,
                    submittedAt: node.submittedAt.flatMap { parseDate($0) }
                )
            }
        }()

        return PullRequest(
            id: id,
            number: number,
            title: title,
            url: prURL,
            state: PRState(rawValue: state) ?? .open,
            isDraft: isDraft,
            createdAt: parseDate(createdAt),
            updatedAt: parseDate(updatedAt),
            author: PRUser(login: author?.login ?? "ghost", avatarURL: author?.avatarUrl.flatMap(URL.init)),
            repository: PRRepository(nameWithOwner: repository.nameWithOwner, url: repoURL),
            headRefName: headRefName,
            baseRefName: baseRefName,
            additions: additions,
            deletions: deletions,
            mergeable: MergeableState(rawValue: mergeable) ?? .unknown,
            reviewDecision: reviewDecision.flatMap(ReviewDecision.init),
            statusCheckRollup: ciState,
            reviews: latestReviews,
            labels: labels.nodes.map { PRLabel(nodeId: $0.id, name: $0.name, color: $0.color, description: $0.description) },
            assignees: assignees.nodes.map { PRUser(login: $0.login, avatarURL: $0.avatarUrl.flatMap(URL.init)) },
            reviewRequests: reviewRequests.nodes.compactMap { node in
                guard let reviewer = node.requestedReviewer else { return nil }
                return PRUser(login: reviewer.login, avatarURL: reviewer.avatarUrl.flatMap(URL.init))
            }
        )
    }
}
