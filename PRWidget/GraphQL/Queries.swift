import Foundation

enum GitHubQueries {
    static let verifyViewer = """
    query {
        viewer {
            login
            avatarUrl
        }
    }
    """

    static let dashboard = """
    query DashboardQuery {
        viewer {
            login
            avatarUrl
        }
        authored: search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
            nodes {
                ... on PullRequest {
                    ...PRFields
                }
            }
        }
        reviewRequested: search(query: "is:pr is:open review-requested:@me archived:false", type: ISSUE, first: 50) {
            nodes {
                ... on PullRequest {
                    ...PRFields
                }
            }
        }
    }

    fragment PRFields on PullRequest {
        id
        number
        title
        url
        body
        state
        isDraft
        createdAt
        updatedAt
        additions
        deletions
        mergeable
        reviewDecision
        headRefName
        baseRefName
        author {
            login
            avatarUrl
        }
        repository {
            nameWithOwner
            url
        }
        comments {
            totalCount
        }
        commits(last: 1) {
            nodes {
                commit {
                    statusCheckRollup {
                        state
                    }
                }
            }
        }
        reviews(last: 10) {
            nodes {
                id
                state
                submittedAt
                author {
                    login
                    avatarUrl
                }
            }
        }
        labels(first: 10) {
            nodes {
                id
                name
                color
                description
            }
        }
        assignees(first: 10) {
            nodes {
                login
                avatarUrl
            }
        }
        reviewRequests(first: 10) {
            nodes {
                requestedReviewer {
                    ... on User {
                        login
                        avatarUrl
                    }
                }
            }
        }
    }
    """

    static let branchList = """
    query BranchList($owner: String!, $name: String!, $after: String) {
        repository(owner: $owner, name: $name) {
            defaultBranchRef {
                name
            }
            refs(refPrefix: "refs/heads/", first: 100, after: $after, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
                pageInfo {
                    hasNextPage
                    endCursor
                }
                nodes {
                    id
                    name
                    target {
                        ... on Commit {
                            oid
                            committedDate
                            author {
                                user {
                                    login
                                }
                                name
                            }
                        }
                    }
                    associatedPullRequests(first: 1, orderBy: {field: CREATED_AT, direction: DESC}) {
                        nodes {
                            number
                            url
                            state
                            baseRefName
                        }
                    }
                }
            }
        }
    }
    """

    static let searchRepositories = """
    query SearchRepos($query: String!) {
        search(query: $query, type: REPOSITORY, first: 10) {
            nodes {
                ... on Repository {
                    nameWithOwner
                    url
                    description
                    stargazerCount
                    isArchived
                }
            }
        }
    }
    """

    static let prDetail = """
    query PRDetailQuery($id: ID!) {
        node(id: $id) {
            ... on PullRequest {
                bodyText
                comments(last: 50) {
                    nodes {
                        id
                        author {
                            login
                            avatarUrl
                        }
                        body
                        createdAt
                        url
                        isMinimized
                    }
                }
                timelineItems(last: 30) {
                    nodes {
                        __typename
                        ... on PullRequestReview {
                            id
                            author { login avatarUrl }
                            state
                            createdAt
                        }
                        ... on IssueComment {
                            id
                            author { login avatarUrl }
                            createdAt
                        }
                        ... on MergedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                        }
                        ... on ClosedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                        }
                        ... on ReopenedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                        }
                        ... on LabeledEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                            label { name }
                        }
                        ... on AssignedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                            assignee { ... on User { login } }
                        }
                        ... on MentionedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                        }
                        ... on HeadRefForcePushedEvent {
                            id
                            actor { login avatarUrl }
                            createdAt
                        }
                    }
                }
                commits(last: 20) {
                    nodes {
                        commit {
                            oid
                            message
                            url
                            author {
                                user {
                                    login
                                    avatarUrl
                                }
                            }
                            statusCheckRollup {
                                contexts(first: 50) {
                                    nodes {
                                        ... on CheckRun {
                                            id
                                            name
                                            status
                                            conclusion
                                            detailsUrl
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                reviewThreads(first: 100) {
                    nodes {
                        id
                        isResolved
                        isOutdated
                        path
                        line
                        startLine
                        diffSide
                        comments(first: 50) {
                            nodes {
                                id
                                author { login avatarUrl }
                                body
                                createdAt
                                url
                            }
                        }
                    }
                }
                changedFiles
            }
        }
    }
    """
}
