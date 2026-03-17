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
        static let isPinned = Persisted<Bool>("PArr.isPinned", default: true)
        static let repoOrder = Persisted<[String]>("PArr.repoOrder", default: [])
        static let selectedLabels = Persisted<[String]>("PArr.selectedLabels", default: [])
        static let excludedLabels = Persisted<[String]>("PArr.excludedLabels", default: [])
        static let selectedAuthors = Persisted<[String]>("PArr.selectedAuthors", default: [])
        static let excludedAuthors = Persisted<[String]>("PArr.excludedAuthors", default: [])
    }

    var state = DashboardState()
    var activeFilter: PRFilter = .all {
        didSet { Keys.activeFilter.save(activeFilter.rawValue) }
    }
    var searchQuery: String = ""
    var collapsedRepos: Set<String> = [] {
        didSet { Keys.collapsedRepos.saveSet(collapsedRepos) }
    }
    var pinnedPRIDs: Set<String> = [] {
        didSet { Keys.pinnedPRIDs.saveSet(pinnedPRIDs) }
    }
    var isPinned: Bool = true {
        didSet { Keys.isPinned.save(isPinned) }
    }
    var selectedLabels: Set<String> = [] {
        didSet { Keys.selectedLabels.saveSet(selectedLabels) }
    }
    var excludedLabels: Set<String> = [] {
        didSet { Keys.excludedLabels.saveSet(excludedLabels) }
    }
    var selectedAuthors: Set<String> = [] {
        didSet { Keys.selectedAuthors.saveSet(selectedAuthors) }
    }
    var excludedAuthors: Set<String> = [] {
        didSet { Keys.excludedAuthors.saveSet(excludedAuthors) }
    }
    var repoOrder: [String] = [] {
        didSet { Keys.repoOrder.save(repoOrder) }
    }

    private let accountManager: AccountManager
    private let client = GitHubGraphQLClient()
    private var fileDiffCache: [String: [PRFileDiff]] = [:]

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        self.activeFilter = PRFilter(rawValue: Keys.activeFilter.load()) ?? .all
        self.collapsedRepos = Keys.collapsedRepos.loadSet()
        self.pinnedPRIDs = Keys.pinnedPRIDs.loadSet()
        self.isPinned = Keys.isPinned.load()
        self.repoOrder = Keys.repoOrder.load()
        self.selectedLabels = Keys.selectedLabels.loadSet()
        self.excludedLabels = Keys.excludedLabels.loadSet()
        self.selectedAuthors = Keys.selectedAuthors.loadSet()
        self.excludedAuthors = Keys.excludedAuthors.loadSet()
    }

    var availableLabels: [String] {
        let allLabels = state.pullRequests.flatMap { $0.labels.map(\.name) }
        return Array(Set(allLabels)).sorted()
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

    var availableAuthors: [String] {
        var seen = Set<String>()
        return state.pullRequests
            .map(\.author.login)
            .filter { seen.insert($0).inserted }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var filteredPRs: [PullRequest] {
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

        return prs.sorted { $0.urgencyScore > $1.urgencyScore }
    }

    var pinnedPRs: [PullRequest] {
        filteredPRs.filter { pinnedPRIDs.contains($0.id) }
    }

    var groupedByRepo: [(repoName: String, prs: [PullRequest])] {
        let unpinned = filteredPRs.filter { !pinnedPRIDs.contains($0.id) }
        let grouped = Dictionary(grouping: unpinned) { $0.repository.nameWithOwner }
        let groups = grouped.map { (repoName: $0.key, prs: $0.value) }

        // Sort by custom order first, then alphabetically for unordered repos
        return groups.sorted { a, b in
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
        // Ensure repoOrder contains all current repos
        let currentRepos = groupedByRepo.map(\.repoName)
        var order = currentRepos
        order.move(fromOffsets: source, toOffset: destination)
        repoOrder = order
    }

    var allCollapsed: Bool {
        let allRepos = Set(filteredPRs.filter { !pinnedPRIDs.contains($0.id) }.map { $0.repository.nameWithOwner })
        return !allRepos.isEmpty && allRepos.isSubset(of: collapsedRepos)
    }

    func refresh() async {
        guard !state.isLoading else { return }
        state.isLoading = true
        state.error = nil

        // Invalidate file diff cache on refresh — PRs may have new commits
        fileDiffCache.removeAll()

        var allPRs: [PullRequest] = []
        var currentUser = ""

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

                // Merge and deduplicate
                var seen = Set<String>()
                for pr in authored + reviewRequested {
                    if seen.insert(pr.id).inserted {
                        allPRs.append(pr)
                    }
                }
            } catch {
                state.error = error.localizedDescription
            }
        }

        state.pullRequests = allPRs
        state.currentUser = currentUser
        state.lastRefreshed = .now
        state.isLoading = false
    }

    func fetchDetail(for pr: PullRequest, force: Bool = false) async -> PRDetail? {
        if !force, let existing = pr.detail { return existing }

        guard let account = accountManager.accounts.first,
              let token = accountManager.token(for: account) else { return nil }

        do {
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
        } catch {
            return nil
        }
    }

    func fetchFileDiffs(for pr: PullRequest, force: Bool = false) async throws -> [PRFileDiff] {
        if !force, let cached = fileDiffCache[pr.id] { return cached }

        guard let account = accountManager.accounts.first,
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
