import Testing
@testable import PRWidget

@Suite("PR Widget Tests")
struct PRWidgetTests {
    @Test("Urgency scoring increases with age and review state")
    func urgencyScoring() {
        let pr = makePR(
            id: "test-1",
            author: "test",
            createdAt: Date().addingTimeInterval(-72 * 3600),
            reviewDecision: .reviewRequired,
            ci: .success
        )

        #expect(pr.urgencyScore > 0)
        #expect(pr.ageText == "3d")
    }

    @Test("Dashboard categories sort correctly")
    func dashboardCategories() {
        let needsReview = makePR(id: "1", author: "other", reviewRequests: [PRUser(login: "me", avatarURL: nil)])
        let readyToShip = makePR(id: "2", author: "me", reviewDecision: .approved, ci: .success, mergeable: .mergeable)
        let waiting = makePR(id: "3", author: "me", reviewDecision: .reviewRequired, ci: .success)

        var state = DashboardState()
        state.currentUser = "me"
        state.pullRequests = [needsReview, readyToShip, waiting]
        state.categorize()

        #expect(state.needsAction.count == 1)
        #expect(state.needsAction.first?.id == "1")
        #expect(state.readyToShip.count == 1)
        #expect(state.readyToShip.first?.id == "2")
        #expect(state.waitingOnOthers.count == 1)
        #expect(state.waitingOnOthers.first?.id == "3")
    }
}

@Suite("Algorithmic Synopsis Tests")
struct AlgorithmicSynopsisTests {
    @Test("Generates synopsis for approved PR ready to merge")
    func approvedPR() {
        let pr = makePR(
            id: "1",
            author: "dev",
            reviewDecision: .approved,
            ci: .success,
            mergeable: .mergeable
        )
        let detail = makeDetail()

        let synopsis = AlgorithmicSynopsis.generate(for: pr, detail: detail)

        #expect(synopsis.provider == .algorithmic)
        #expect(!synopsis.summary.isEmpty)
        #expect(synopsis.actionItems.contains("Ready to merge"))
    }

    @Test("Generates synopsis for PR with failing CI")
    func failingCI() {
        let pr = makePR(id: "2", author: "dev", ci: .failure)
        let detail = makeDetail()

        let synopsis = AlgorithmicSynopsis.generate(for: pr, detail: detail)

        #expect(synopsis.actionItems.contains("CI checks are failing"))
        #expect(synopsis.urgencyReason != nil)
    }

    @Test("Generates synopsis for PR with merge conflicts")
    func mergeConflicts() {
        let pr = makePR(id: "3", author: "dev", mergeable: .conflicting)
        let detail = makeDetail()

        let synopsis = AlgorithmicSynopsis.generate(for: pr, detail: detail)

        #expect(synopsis.actionItems.contains("Resolve merge conflicts"))
    }

    @Test("Generates synopsis for draft PR")
    func draftPR() {
        let pr = makePR(id: "4", author: "dev", isDraft: true)
        let detail = makeDetail()

        let synopsis = AlgorithmicSynopsis.generate(for: pr, detail: detail)

        #expect(synopsis.actionItems.contains("Mark as ready for review when complete"))
        #expect(synopsis.summary.contains("draft"))
    }
}

@Suite("PR Filter Tests")
struct PRFilterTests {
    @Test("MyPRs filter shows only authored PRs")
    func myPRsFilter() {
        let mine = makePR(id: "1", author: "me")
        let theirs = makePR(id: "2", author: "other")

        let filtered = applyFilter(.myPRs, prs: [mine, theirs], currentUser: "me")

        #expect(filtered.count == 1)
        #expect(filtered.first?.id == "1")
    }

    @Test("ReviewRequested filter shows PRs where current user is requested")
    func reviewRequestedFilter() {
        let requested = makePR(id: "1", author: "other", reviewRequests: [PRUser(login: "me", avatarURL: nil)])
        let notRequested = makePR(id: "2", author: "other")

        let filtered = applyFilter(.reviewRequested, prs: [requested, notRequested], currentUser: "me")

        #expect(filtered.count == 1)
        #expect(filtered.first?.id == "1")
    }

    @Test("BlockedByMe filter shows PRs with pending review from current user")
    func blockedByMeFilter() {
        let blocked = makePR(id: "1", author: "other", reviewRequests: [PRUser(login: "me", avatarURL: nil)])
        let notBlocked = makePR(id: "2", author: "other")

        let filtered = applyFilter(.blockedByMe, prs: [blocked, notBlocked], currentUser: "me")

        #expect(filtered.count == 1)
        #expect(filtered.first?.id == "1")
    }

    @Test("All filter returns everything")
    func allFilter() {
        let prs = [makePR(id: "1", author: "a"), makePR(id: "2", author: "b")]
        let filtered = applyFilter(.all, prs: prs, currentUser: "me")
        #expect(filtered.count == 2)
    }

    private func applyFilter(_ filter: PRFilter, prs: [PullRequest], currentUser: String) -> [PullRequest] {
        switch filter {
        case .all: return prs
        case .myPRs: return prs.filter { $0.author.login == currentUser }
        case .reviewRequested: return prs.filter { $0.reviewRequests.contains { $0.login == currentUser } }
        case .mentioned: return prs // Would need detail
        case .blockedByMe:
            return prs.filter { pr in
                pr.reviewRequests.contains { $0.login == currentUser }
                && pr.reviews.allSatisfy { $0.author.login != currentUser || $0.state == .pending }
            }
        }
    }
}

@Suite("Search Tests")
struct SearchTests {
    @Test("Search matches PR title")
    func searchTitle() {
        let pr = makePR(id: "1", author: "dev", title: "Fix authentication bug")
        let results = search("auth", in: [pr])
        #expect(results.count == 1)
    }

    @Test("Search matches repo name")
    func searchRepo() {
        let pr = makePR(id: "1", author: "dev", repo: "myorg/myrepo")
        let results = search("myrepo", in: [pr])
        #expect(results.count == 1)
    }

    @Test("Search matches branch name")
    func searchBranch() {
        let pr = makePR(id: "1", author: "dev", headRef: "feature/login")
        let results = search("login", in: [pr])
        #expect(results.count == 1)
    }

    @Test("Search is case insensitive")
    func searchCaseInsensitive() {
        let pr = makePR(id: "1", author: "dev", title: "Fix BIG Bug")
        let results = search("big bug", in: [pr])
        #expect(results.count == 1)
    }

    @Test("Search with no matches returns empty")
    func searchNoMatch() {
        let pr = makePR(id: "1", author: "dev", title: "Something else")
        let results = search("nonexistent", in: [pr])
        #expect(results.isEmpty)
    }

    private func search(_ query: String, in prs: [PullRequest]) -> [PullRequest] {
        let q = query.lowercased()
        return prs.filter { pr in
            pr.title.lowercased().contains(q)
            || pr.repository.nameWithOwner.lowercased().contains(q)
            || pr.headRefName.lowercased().contains(q)
            || pr.baseRefName.lowercased().contains(q)
            || pr.author.login.lowercased().contains(q)
        }
    }
}

@Suite("Repo Grouping Tests")
struct RepoGroupingTests {
    @Test("Groups PRs by repository")
    func groupsByRepo() {
        let pr1 = makePR(id: "1", author: "dev", repo: "org/repo-a")
        let pr2 = makePR(id: "2", author: "dev", repo: "org/repo-b")
        let pr3 = makePR(id: "3", author: "dev", repo: "org/repo-a")

        let grouped = Dictionary(grouping: [pr1, pr2, pr3]) { $0.repository.nameWithOwner }
            .map { (repoName: $0.key, prs: $0.value) }
            .sorted { $0.repoName < $1.repoName }

        #expect(grouped.count == 2)
        #expect(grouped[0].repoName == "org/repo-a")
        #expect(grouped[0].prs.count == 2)
        #expect(grouped[1].repoName == "org/repo-b")
        #expect(grouped[1].prs.count == 1)
    }

    @Test("Groups are sorted alphabetically")
    func sortedAlphabetically() {
        let pr1 = makePR(id: "1", author: "dev", repo: "org/zebra")
        let pr2 = makePR(id: "2", author: "dev", repo: "org/alpha")

        let grouped = Dictionary(grouping: [pr1, pr2]) { $0.repository.nameWithOwner }
            .map { (repoName: $0.key, prs: $0.value) }
            .sorted { $0.repoName < $1.repoName }

        #expect(grouped[0].repoName == "org/alpha")
        #expect(grouped[1].repoName == "org/zebra")
    }
}

// MARK: - Test Helpers

private func makePR(
    id: String,
    author: String,
    title: String = "Test PR",
    repo: String = "test/test",
    headRef: String = "feature",
    isDraft: Bool = false,
    createdAt: Date = Date(),
    reviewDecision: ReviewDecision? = nil,
    ci: CIStatus = .unknown,
    mergeable: MergeableState = .unknown,
    reviewRequests: [PRUser] = [],
    reviews: [PRReview] = []
) -> PullRequest {
    PullRequest(
        id: id,
        number: Int(id) ?? 0,
        title: title,
        url: URL(string: "https://github.com/\(repo)/pull/\(id)")!,
        state: .open,
        isDraft: isDraft,
        createdAt: createdAt,
        updatedAt: Date(),
        author: PRUser(login: author, avatarURL: nil),
        repository: PRRepository(nameWithOwner: repo, url: URL(string: "https://github.com/\(repo)")!),
        headRefName: headRef,
        baseRefName: "main",
        additions: 10,
        deletions: 5,
        mergeable: mergeable,
        reviewDecision: reviewDecision,
        statusCheckRollup: ci,
        reviews: reviews,
        labels: [],
        assignees: [],
        reviewRequests: reviewRequests,
        commentCount: 0,
        taskProgress: nil
    )
}

private func makeDetail(
    comments: [PRComment] = [],
    changedFiles: Int = 5
) -> PRDetail {
    PRDetail(
        comments: comments,
        timelineEvents: [],
        commits: [],
        checkRuns: [],
        changedFiles: changedFiles,
        bodyText: ""
    )
}
