import Foundation
import Observation
import CatalystSwift

@MainActor
@Observable
final class DashboardStore {
    private enum Keys {
        static let activeFilter = Persisted<String>("PArr.activeFilter", default: PRFilter.all.rawValue)
        static let collapsedRepos = Persisted<[String]>("PArr.collapsedRepos", default: [])
        static let pinnedPRIDs = Persisted<[String]>("PArr.pinnedPRIDs", default: [])
        static let repoOrder = Persisted<[String]>("PArr.repoOrder", default: [])
        static let selectedLabels = Persisted<[String]>("PArr.selectedLabels", default: [])
        static let excludedLabels = Persisted<[String]>("PArr.excludedLabels", default: [])
        static let selectedAuthors = Persisted<[String]>("PArr.selectedAuthors", default: [])
        static let excludedAuthors = Persisted<[String]>("PArr.excludedAuthors", default: [])
    }

    var state = DashboardState()
    var activeFilter: PRFilter = .all {
        didSet {
            Keys.activeFilter.save(activeFilter.rawValue)
            recomputeFilteredResults()
        }
    }
    var searchQuery: String = "" {
        didSet { recomputeFilteredResults() }
    }
    var collapsedRepos: Set<String> = [] {
        didSet { Keys.collapsedRepos.saveSet(collapsedRepos) }
    }
    var pinnedPRIDs: Set<String> = [] {
        didSet {
            Keys.pinnedPRIDs.saveSet(pinnedPRIDs)
            recomputeFilteredResults()
        }
    }
    var selectedLabels: Set<String> = [] {
        didSet {
            Keys.selectedLabels.saveSet(selectedLabels)
            recomputeFilteredResults()
        }
    }
    var excludedLabels: Set<String> = [] {
        didSet {
            Keys.excludedLabels.saveSet(excludedLabels)
            recomputeFilteredResults()
        }
    }
    var selectedAuthors: Set<String> = [] {
        didSet {
            Keys.selectedAuthors.saveSet(selectedAuthors)
            recomputeFilteredResults()
        }
    }
    var excludedAuthors: Set<String> = [] {
        didSet {
            Keys.excludedAuthors.saveSet(excludedAuthors)
            recomputeFilteredResults()
        }
    }
    var repoOrder: [String] = [] {
        didSet {
            Keys.repoOrder.save(repoOrder)
            recomputeFilteredResults()
        }
    }

    // MARK: - Cached filter/group results (Perf P2)

    private(set) var filteredPRs: [PullRequest] = []
    private(set) var pinnedPRs: [PullRequest] = []
    private(set) var groupedByRepo: [(repoName: String, prs: [PullRequest])] = []

    // MARK: - Cached label/author lists (Perf P3)

    private(set) var availableLabels: [String] = []
    private(set) var availableAuthors: [String] = []

    private let accountManager: AccountManager
    private let client = GitHubGraphQLClient()
    private var fileDiffCache: [String: [PRFileDiff]] = [:]

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        self.activeFilter = PRFilter(rawValue: Keys.activeFilter.load()) ?? .all
        self.collapsedRepos = Keys.collapsedRepos.loadSet()
        self.pinnedPRIDs = Keys.pinnedPRIDs.loadSet()
        self.repoOrder = Keys.repoOrder.load()
        self.selectedLabels = Keys.selectedLabels.loadSet()
        self.excludedLabels = Keys.excludedLabels.loadSet()
        self.selectedAuthors = Keys.selectedAuthors.loadSet()
        self.excludedAuthors = Keys.excludedAuthors.loadSet()
    }

    /// All unique PRLabel objects across all PRs, keyed by name (keeps first seen)
    var allLabelObjects: [String: PRLabel] {
        var map: [String: PRLabel] = [:]
        for pr in state.pullRequests {
            for label in pr.labels where map[label.name] == nil {
                map[label.name] = label
            }
        }
        return map
    }

    /// Labels available to add to a PR (exist on other PRs in same repo, not already on this PR)
    func labelsToAdd(for pr: PullRequest) -> [PRLabel] {
        let existingNames = Set(pr.labels.map(\.name))
        let repoLabels = state.pullRequests
            .filter { $0.repository.nameWithOwner == pr.repository.nameWithOwner }
            .flatMap(\.labels)
        var seen = Set<String>()
        return repoLabels.filter { label in
            !existingNames.contains(label.name) && seen.insert(label.name).inserted
        }.sorted { $0.name < $1.name }
    }

    func updateLabels(for prID: String, labels: [PRLabel]) {
        if let index = state.pullRequests.firstIndex(where: { $0.id == prID }) {
            state.pullRequests[index].labels = labels
        }
    }

    /// All unique labels seen in the same repo as this PR
    func repoLabels(for pr: PullRequest) -> [PRLabel] {
        let repoLabels = state.pullRequests
            .filter { $0.repository.nameWithOwner == pr.repository.nameWithOwner }
            .flatMap(\.labels)
        var seen = Set<String>()
        return repoLabels.filter { seen.insert($0.name).inserted }
            .sorted { $0.name < $1.name }
    }

    // MARK: - Recompute cached results

    /// Recomputes filteredPRs, pinnedPRs, and groupedByRepo from current state + filter inputs.
    private func recomputeFilteredResults() {
        var prs = state.pullRequests
        let currentUser = state.currentUser

        // Apply filter
        switch activeFilter {
        case .all:
            break
        case .needsAction:
            let ids = Set(state.needsAction.map(\.id))
            prs = prs.filter { ids.contains($0.id) }
        case .readyToShip:
            let ids = Set(state.readyToShip.map(\.id))
            prs = prs.filter { ids.contains($0.id) }
        case .waitingOnOthers:
            let ids = Set(state.waitingOnOthers.map(\.id))
            prs = prs.filter { ids.contains($0.id) }
        case .myPRs:
            prs = prs.filter { $0.author.login == currentUser }
        case .reviewRequested:
            prs = prs.filter { $0.reviewRequests.contains { $0.login == currentUser } }
        case .mentioned:
            prs = prs.filter { pr in
                pr.detail?.comments.contains { comment in
                    comment.body.contains("@\(currentUser)")
                } ?? false
            }
        case .blockedByMe:
            prs = prs.filter { pr in
                pr.reviewRequests.contains { $0.login == currentUser }
                && pr.reviews.allSatisfy { $0.author.login != currentUser || $0.state == .pending }
            }
        }

        // Apply search
        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            prs = prs.filter { pr in
                pr.title.lowercased().contains(q)
                || pr.repository.nameWithOwner.lowercased().contains(q)
                || pr.headRefName.lowercased().contains(q)
                || pr.baseRefName.lowercased().contains(q)
                || pr.author.login.lowercased().contains(q)
            }
        }

        // Apply label include filter
        if !selectedLabels.isEmpty {
            prs = prs.filter { pr in
                pr.labels.contains { selectedLabels.contains($0.name) }
            }
        }
        // Apply label exclude filter
        if !excludedLabels.isEmpty {
            prs = prs.filter { pr in
                !pr.labels.contains { excludedLabels.contains($0.name) }
            }
        }

        // Apply author include filter
        if !selectedAuthors.isEmpty {
            prs = prs.filter { selectedAuthors.contains($0.author.login) }
        }
        // Apply author exclude filter
        if !excludedAuthors.isEmpty {
            prs = prs.filter { !excludedAuthors.contains($0.author.login) }
        }

        let sorted = prs.sorted { $0.urgencyScore > $1.urgencyScore }
        filteredPRs = sorted
        pinnedPRs = sorted.filter { pinnedPRIDs.contains($0.id) }

        // Grouped by repo (unpinned only)
        let unpinned = sorted.filter { !pinnedPRIDs.contains($0.id) }
        let grouped = Dictionary(grouping: unpinned) { $0.repository.nameWithOwner }
        let groups = grouped.map { (repoName: $0.key, prs: $0.value) }

        groupedByRepo = groups.sorted { a, b in
            let aIdx = repoOrder.firstIndex(of: a.repoName)
            let bIdx = repoOrder.firstIndex(of: b.repoName)
            switch (aIdx, bIdx) {
            case let (.some(ai), .some(bi)):
                return ai < bi
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return a.repoName.localizedCaseInsensitiveCompare(b.repoName) == .orderedAscending
            }
        }
    }

    /// Recomputes cached availableLabels and availableAuthors from current pullRequests.
    private func recomputeAvailableLists() {
        let allLabels = state.pullRequests.flatMap { $0.labels.map(\.name) }
        availableLabels = Array(Set(allLabels)).sorted()

        var seen = Set<String>()
        availableAuthors = state.pullRequests
            .map(\.author.login)
            .filter { seen.insert($0).inserted }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func togglePin(_ prID: String) {
        if pinnedPRIDs.contains(prID) {
            pinnedPRIDs.remove(prID)
        } else {
            pinnedPRIDs.insert(prID)
        }
    }

    func isPinned(_ prID: String) -> Bool {
        pinnedPRIDs.contains(prID)
    }

    func collapseAll() {
        let allRepos = Set(filteredPRs.map { $0.repository.nameWithOwner })
        collapsedRepos = allRepos
    }

    func expandAll() {
        collapsedRepos.removeAll()
    }

    func moveRepo(from source: IndexSet, to destination: Int) {
        let currentRepos = groupedByRepo.map(\.repoName)
        var order = currentRepos
        order.move(fromOffsets: source, toOffset: destination)
        repoOrder = order
    }

    var allCollapsed: Bool {
        let allRepos = Set(filteredPRs.filter { !pinnedPRIDs.contains($0.id) }.map { $0.repository.nameWithOwner })
        return !allRepos.isEmpty && allRepos.isSubset(of: collapsedRepos)
    }

    // MARK: - Account lookup helper (B1)

    /// Finds the account matching the PR's sourceAccountID, falling back to first account.
    func account(for pr: PullRequest) -> GitHubAccount? {
        if let sourceID = pr.sourceAccountID,
           let match = accountManager.accounts.first(where: { $0.id == sourceID }) {
            return match
        }
        return accountManager.accounts.first
    }

    // MARK: - Refresh (B1 multi-account, B4 partial failure)

    func refresh() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        state.error = nil

        // Invalidate file diff cache on refresh — PRs may have new commits
        fileDiffCache.removeAll()

        var allPRs: [PullRequest] = []
        var currentUser = ""
        var errors: [String] = []
        var failedAccountIDs: Set<UUID> = []

        for account in accountManager.accounts {
            guard let token = accountManager.token(for: account) else { continue }

            do {
                let response: DashboardResponse = try await client.execute(
                    query: GitHubQueries.dashboard,
                    token: token,
                    endpoint: account.graphQLEndpoint
                )

                if currentUser.isEmpty {
                    currentUser = response.viewer.login
                }

                let authored = response.authored.nodes.compactMap { $0?.toPullRequest() }
                let reviewRequested = response.reviewRequested.nodes.compactMap { $0?.toPullRequest() }

                // Merge, deduplicate, and stamp sourceAccountID (B1)
                var seen = Set<String>()
                for var pr in authored + reviewRequested {
                    if seen.insert(pr.id).inserted {
                        pr.sourceAccountID = account.id
                        allPRs.append(pr)
                    }
                }
            } catch {
                errors.append("\(account.displayName): \(error.localizedDescription)")
                failedAccountIDs.insert(account.id)
            }
        }

        // Partial failure handling (B4): preserve existing PRs from failed accounts
        if !failedAccountIDs.isEmpty {
            let preservedPRs = state.pullRequests.filter { pr in
                guard let sourceID = pr.sourceAccountID else { return false }
                return failedAccountIDs.contains(sourceID)
            }
            // Merge preserved PRs (avoid duplicates with successfully-fetched ones)
            let fetchedIDs = Set(allPRs.map(\.id))
            for pr in preservedPRs where !fetchedIDs.contains(pr.id) {
                allPRs.append(pr)
            }
        }

        if !errors.isEmpty {
            state.error = errors.joined(separator: "\n")
        }

        state.pullRequests = allPRs
        state.currentUser = currentUser
        state.lastRefreshed = .now
        state.isLoading = false

        // Recompute all cached derived data
        state.categorize()
        recomputeAvailableLists()
        recomputeFilteredResults()
    }

    // MARK: - Fetch Detail (B1 account lookup, B5 error propagation)

    func fetchDetail(for pr: PullRequest, force: Bool = false) async throws -> PRDetail {
        if !force, let existing = pr.detail { return existing }

        guard let account = account(for: pr),
              let token = accountManager.token(for: account) else {
            throw APIError.noToken
        }

        let response: PRDetailResponse = try await client.execute(
            query: GitHubQueries.prDetail,
            variables: ["id": pr.id],
            token: token,
            endpoint: account.graphQLEndpoint
        )
        let detail = response.node.toPRDetail()

        // Update the stored PR with detail
        if let index = state.pullRequests.firstIndex(where: { $0.id == pr.id }) {
            state.pullRequests[index].detail = detail
        }
        return detail
    }

    // MARK: - Fetch File Diffs (B1 account lookup)

    func fetchFileDiffs(for pr: PullRequest, force: Bool = false) async throws -> [PRFileDiff] {
        if !force, let cached = fileDiffCache[pr.id] { return cached }

        guard let account = account(for: pr),
              let token = accountManager.token(for: account) else {
            throw APIError.noToken
        }

        let parts = pr.repository.nameWithOwner.split(separator: "/")
        guard parts.count == 2 else { return [] }
        let owner = String(parts[0])
        let repo = String(parts[1])

        let restFiles = try await client.fetchFileDiffs(
            owner: owner,
            repo: repo,
            number: pr.number,
            token: token
        )

        // Get review threads from the already-fetched detail
        let reviewThreads = pr.detail?.reviewThreads ?? []

        let diffs = restFiles.map { restFile in
            let status = FileChangeType(rawValue: restFile.status) ?? .modified
            let threadsForFile = reviewThreads.filter { $0.path == restFile.filename }

            return PRFileDiff(
                id: restFile.sha.isEmpty ? restFile.filename : restFile.sha,
                path: restFile.filename,
                status: status,
                additions: restFile.additions,
                deletions: restFile.deletions,
                patch: restFile.patch,
                reviewThreads: threadsForFile
            )
        }

        fileDiffCache[pr.id] = diffs
        return diffs
    }

    func replyToReviewThread(
        threadId: String,
        body: String,
        token: String,
        endpoint: URL
    ) async throws -> PRReviewComment {
        let response: AddReviewThreadReplyResponse = try await client.execute(
            query: GitHubMutations.addReviewThreadReply,
            variables: ["threadId": threadId, "body": body],
            token: token,
            endpoint: endpoint
        )

        let node = response.addPullRequestReviewThreadReply.comment

        return PRReviewComment(
            id: node.id,
            author: PRUser(
                login: node.author?.login ?? "ghost",
                avatarURL: node.author?.avatarUrl.flatMap(URL.init)
            ),
            body: node.body,
            createdAt: .parseGitHub(node.createdAt),
            url: node.url.flatMap(URL.init)
        )
    }
}
