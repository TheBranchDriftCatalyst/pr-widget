import Foundation
import Observation
import CatalystSwift
import TelemetryDeck

@MainActor
@Observable
final class BranchCleanupStore {
    private enum Keys {
        static let workspaceRoot = Persisted<String>("PArr.branchCleanup.workspaceRoot", default: "")
        static let selectedCommitters = Persisted<[String]>("PArr.branchCleanup.selectedCommitters", default: [])
        static let excludedCommitters = Persisted<[String]>("PArr.branchCleanup.excludedCommitters", default: [])
        static let selectedRepos = Persisted<[String]>("PArr.branchCleanup.selectedRepos", default: [])
        static let excludedRepos = Persisted<[String]>("PArr.branchCleanup.excludedRepos", default: [])
    }

    // MARK: - State

    var branches: [BranchInfo] = []
    var isLoading = false
    var error: String?

    var searchQuery = "" {
        didSet { recomputeFilteredResults() }
    }
    var selectedCommitters: Set<String> = [] {
        didSet { Keys.selectedCommitters.saveSet(selectedCommitters); recomputeFilteredResults() }
    }
    var excludedCommitters: Set<String> = [] {
        didSet { Keys.excludedCommitters.saveSet(excludedCommitters); recomputeFilteredResults() }
    }
    var selectedRepos: Set<String> = [] {
        didSet { Keys.selectedRepos.saveSet(selectedRepos); recomputeFilteredResults() }
    }
    var excludedRepos: Set<String> = [] {
        didSet { Keys.excludedRepos.saveSet(excludedRepos); recomputeFilteredResults() }
    }
    var selectedBranchIDs: Set<String> = []
    var workspaceRoot: String = "" {
        didSet { Keys.workspaceRoot.save(workspaceRoot) }
    }

    // MARK: - Derived

    private(set) var filteredBranches: [BranchInfo] = []
    private(set) var availableCommitters: [String] = []
    private(set) var availableRepos: [String] = []

    // MARK: - Dependencies

    private let accountManager: AccountManager
    private let client = GitHubGraphQLClient()
    private let localGit = LocalGitService()

    /// Discovered repos from workspace, keyed by nameWithOwner → local path.
    private var discoveredLocalPaths: [String: String] = [:]

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        self.selectedCommitters = Set(Keys.selectedCommitters.load())
        self.excludedCommitters = Set(Keys.excludedCommitters.load())
        self.selectedRepos = Set(Keys.selectedRepos.load())
        self.excludedRepos = Set(Keys.excludedRepos.load())
        self.workspaceRoot = Keys.workspaceRoot.load()
    }

    // MARK: - Workspace

    func setWorkspaceRoot(_ path: String) {
        workspaceRoot = path
        if !path.isEmpty {
            Task { await refreshAllBranches() }
        } else {
            branches = []
            discoveredLocalPaths = [:]
            recomputeAvailableLists()
            recomputeFilteredResults()
        }
    }

    // MARK: - Refresh

    func refreshAllBranches() async {
        guard !isLoading else {
            NSLog("[PArr] Branch refresh skipped — already loading")
            return
        }
        guard !workspaceRoot.isEmpty else {
            NSLog("[PArr] No workspace root set")
            return
        }

        isLoading = true
        error = nil

        // Scan workspace for git repos
        let discovered = await localGit.discoverRepos(in: workspaceRoot)
        discoveredLocalPaths = Dictionary(discovered.map { ($0.nameWithOwner, $0.localPath) }, uniquingKeysWith: { _, last in last })
        NSLog("[PArr] Discovered %d repos in workspace", discovered.count)

        guard let defaultAccount = accountManager.accounts.first,
              let token = accountManager.token(for: defaultAccount) else {
            isLoading = false
            error = "No GitHub account configured"
            return
        }

        var allBranches: [BranchInfo] = []
        var errors: [String] = []

        for repo in discovered {
            let tracked = TrackedRepository(
                nameWithOwner: repo.nameWithOwner,
                url: URL(string: "https://github.com/\(repo.nameWithOwner)") ?? URL(string: "https://github.com")!,
                accountID: defaultAccount.id
            )
            do {
                let repoBranches = try await fetchBranches(for: tracked, localPath: repo.localPath)
                NSLog("[PArr] Fetched %d branches for %@", repoBranches.count, repo.nameWithOwner)
                allBranches.append(contentsOf: repoBranches)
            } catch {
                NSLog("[PArr] Error fetching branches for %@: %@", repo.nameWithOwner, error.localizedDescription)
                errors.append("\(repo.nameWithOwner): \(error.localizedDescription)")
            }
        }

        NSLog("[PArr] Branch refresh complete: %d total branches", allBranches.count)
        branches = allBranches
        isLoading = false
        self.error = errors.isEmpty ? nil : errors.joined(separator: "\n")

        recomputeAvailableLists()
        recomputeFilteredResults()
    }

    // MARK: - Fetch Branches for Repo

    private func fetchBranches(for repo: TrackedRepository, localPath: String) async throws -> [BranchInfo] {
        guard let account = accountManager.accounts.first(where: { $0.id == repo.accountID }),
              let token = accountManager.token(for: account) else {
            throw APIError.noToken
        }

        // Fetch remote branches with pagination
        var remoteBranches: [BranchRefNode] = []
        var defaultBranchName: String?
        var cursor: String?

        let owner = repo.owner
        let repoName = repo.name

        repeat {
            let response: BranchListResponse = try await Self.fetchBranchPage(
                client: client, owner: owner, name: repoName,
                cursor: cursor, token: token, endpoint: account.graphQLEndpoint
            )

            guard let repoNode = response.repository else {
                NSLog("[PArr] Repository %@ not found on GitHub — showing local branches only", repo.nameWithOwner)
                break
            }

            if defaultBranchName == nil {
                defaultBranchName = repoNode.defaultBranchRef?.name
            }

            remoteBranches.append(contentsOf: repoNode.refs.nodes)

            if repoNode.refs.pageInfo.hasNextPage {
                cursor = repoNode.refs.pageInfo.endCursor
            } else {
                cursor = nil
            }
        } while cursor != nil

        // Fetch local branches
        var localBranches: [LocalBranchInfo] = []
        var localMergedToMain: Set<String> = []
        var localMergedToDevelop: Set<String> = []

        localBranches = (try? await localGit.listBranches(repoPath: localPath)) ?? []

        // Check merge status locally
        localMergedToMain = await mergedBranchNames(
            targets: [defaultBranchName, "main", "master"].compactMap { $0 },
            from: localBranches, repoPath: localPath
        )
        localMergedToDevelop = await mergedBranchNames(
            targets: ["develop", "development"],
            from: localBranches, repoPath: localPath
        )

        let localBranchNames = Set(localBranches.map(\.name))
        let remoteBranchNames = Set(remoteBranches.map(\.name))
        let localByName = Dictionary(localBranches.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })

        let bothCount = localBranchNames.intersection(remoteBranchNames).count
        let localOnly = localBranchNames.subtracting(remoteBranchNames).count
        let remoteOnly = remoteBranchNames.subtracting(localBranchNames).count
        NSLog("[PArr] %@ — %d remote, %d local, %d both, %d local-only, %d remote-only",
              repo.nameWithOwner, remoteBranches.count, localBranches.count, bothCount, localOnly, remoteOnly)

        var results: [BranchInfo] = []

        // Map remote branches (may also exist locally → merged into single row)
        for ref in remoteBranches {
            let hasLocal = localBranchNames.contains(ref.name)
            let location: BranchLocation = hasLocal ? .both : .remote
            let localInfo = localByName[ref.name]

            let mergedToMain = computeMergeStatus(
                branchName: ref.name,
                targetNames: [defaultBranchName, "main", "master"].compactMap { $0 },
                associatedPR: ref.associatedPullRequests.nodes.first,
                localMergedSet: localMergedToMain
            )
            let mergedToDevelop = computeMergeStatus(
                branchName: ref.name,
                targetNames: ["develop", "development"],
                associatedPR: ref.associatedPullRequests.nodes.first,
                localMergedSet: localMergedToDevelop
            )

            let committer = ref.target?.author?.user?.login
                ?? ref.target?.author?.name
                ?? localInfo?.lastCommitter
                ?? "unknown"

            let date: Date
            if let dateStr = ref.target?.committedDate {
                date = .parseGitHub(dateStr)
            } else {
                date = localInfo?.lastCommitDate ?? .distantPast
            }

            let pr = ref.associatedPullRequests.nodes.first.flatMap { node -> BranchPRInfo? in
                guard let url = URL(string: node.url) else { return nil }
                return BranchPRInfo(number: node.number, url: url, state: node.state, baseRefName: node.baseRefName)
            }

            results.append(BranchInfo(
                id: ref.id,
                name: ref.name,
                repository: repo,
                location: location,
                associatedPR: pr,
                mergedToDevelop: mergedToDevelop,
                mergedToMain: mergedToMain,
                lastCommitter: committer,
                lastActivity: date,
                refNodeID: ref.id,
                defaultBranchName: defaultBranchName,
                isCurrentLocal: localInfo?.isCurrent ?? false
            ))
        }

        // Add local-only branches
        for local in localBranches where !remoteBranchNames.contains(local.name) {
            let mergedToMain = localMergedToMain.contains(local.name) ? MergeStatus.merged : .notMerged
            let mergedToDevelop = localMergedToDevelop.contains(local.name) ? MergeStatus.merged : .notMerged

            results.append(BranchInfo(
                id: "local:\(repo.nameWithOwner):\(local.name)",
                name: local.name,
                repository: repo,
                location: .local,
                associatedPR: nil,
                mergedToDevelop: mergedToDevelop,
                mergedToMain: mergedToMain,
                lastCommitter: local.lastCommitter,
                lastActivity: local.lastCommitDate,
                refNodeID: nil,
                defaultBranchName: defaultBranchName,
                isCurrentLocal: local.isCurrent
            ))
        }

        return results
    }

    // MARK: - Delete

    func deleteBranch(_ branch: BranchInfo, remote: Bool, local: Bool) async throws {
        NSLog("[PArr] Deleting branch '%@' in %@ (remote=%d, local=%d, location=%@)",
              branch.name, branch.repository.nameWithOwner,
              remote ? 1 : 0, local ? 1 : 0, String(describing: branch.location))

        if remote {
            guard let refID = branch.refNodeID else {
                NSLog("[PArr] ⚠️ Skip remote delete for '%@' — no ref node ID (local-only branch)", branch.name)
                if !local {
                    throw LocalGitService.GitError.commandFailed("No remote ref ID for branch '\(branch.name)'")
                }
                // Continue to local delete
                return
            }
            guard let account = accountManager.accounts.first(where: { $0.id == branch.repository.accountID }),
                  let token = accountManager.token(for: account) else {
                NSLog("[PArr] ❌ Remote delete failed for '%@' — no token", branch.name)
                throw APIError.noToken
            }
            let _: DeleteRefResponse = try await client.execute(
                query: GitHubMutations.deleteRef,
                variables: ["refId": refID],
                token: token,
                endpoint: account.graphQLEndpoint
            )
            NSLog("[PArr] ✓ Remote branch '%@' deleted from %@", branch.name, branch.repository.nameWithOwner)
        }

        if local {
            if let localPath = discoveredLocalPaths[branch.repository.nameWithOwner] {
                try await localGit.deleteBranch(branch.name, repoPath: localPath)
                NSLog("[PArr] ✓ Local branch '%@' deleted from %@", branch.name, localPath)
            } else {
                NSLog("[PArr] ⚠️ Skip local delete for '%@' — no local path found for %@", branch.name, branch.repository.nameWithOwner)
            }
        }

        branches.removeAll { $0.id == branch.id }
        selectedBranchIDs.remove(branch.id)
        recomputeFilteredResults()
        NSLog("[PArr] ✓ Branch '%@' removed from list", branch.name)
        TelemetryDeck.signal("branchDeleted", parameters: [
            "location": String(describing: branch.location),
            "remote": remote ? "true" : "false",
            "local": local ? "true" : "false",
        ])
    }

    func deleteSelectedBranches(remote: Bool, local: Bool) async {
        let toDelete = branches.filter { selectedBranchIDs.contains($0.id) && $0.isDeletable }
        NSLog("[PArr] Batch delete: %d branches (remote=%d, local=%d)", toDelete.count, remote ? 1 : 0, local ? 1 : 0)
        var errors: [String] = []
        var successCount = 0

        for branch in toDelete {
            do {
                let shouldDeleteRemote = remote && branch.location != .local
                let shouldDeleteLocal = local && branch.location != .remote
                try await deleteBranch(branch, remote: shouldDeleteRemote, local: shouldDeleteLocal)
                successCount += 1
            } catch {
                NSLog("[PArr] ❌ Failed to delete '%@': %@", branch.name, error.localizedDescription)
                errors.append("\(branch.name): \(error.localizedDescription)")
            }
        }

        NSLog("[PArr] Batch delete complete: %d/%d succeeded", successCount, toDelete.count)
        if !errors.isEmpty {
            self.error = errors.joined(separator: "\n")
        }
    }

    // MARK: - Selection

    func toggleSelection(_ branchID: String) {
        if selectedBranchIDs.contains(branchID) {
            selectedBranchIDs.remove(branchID)
        } else {
            selectedBranchIDs.insert(branchID)
        }
    }

    func selectAllVisible() {
        selectedBranchIDs = Set(filteredBranches.filter(\.isDeletable).map(\.id))
    }

    func deselectAll() {
        selectedBranchIDs.removeAll()
    }

    // MARK: - Filtering

    private func recomputeFilteredResults() {
        var result = branches

        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedStandardContains(searchQuery)
                || $0.repository.nameWithOwner.localizedStandardContains(searchQuery)
                || $0.lastCommitter.localizedStandardContains(searchQuery)
            }
        }

        // Include/exclude committers
        if !selectedCommitters.isEmpty {
            result = result.filter { selectedCommitters.contains($0.lastCommitter) }
        }
        if !excludedCommitters.isEmpty {
            result = result.filter { !excludedCommitters.contains($0.lastCommitter) }
        }

        // Include/exclude repos
        if !selectedRepos.isEmpty {
            result = result.filter { selectedRepos.contains($0.repository.nameWithOwner) }
        }
        if !excludedRepos.isEmpty {
            result = result.filter { !excludedRepos.contains($0.repository.nameWithOwner) }
        }

        let sorted = result.sorted { $0.lastActivity > $1.lastActivity }
        if filteredBranches != sorted {
            filteredBranches = sorted
        }
    }

    private func recomputeAvailableLists() {
        let committers = Set(branches.map(\.lastCommitter)).sorted()
        if availableCommitters != committers {
            availableCommitters = committers
        }

        let repos = Set(branches.map(\.repository.nameWithOwner)).sorted()
        if availableRepos != repos {
            availableRepos = repos
        }
    }

    // MARK: - Helpers

    private func computeMergeStatus(
        branchName: String,
        targetNames: [String],
        associatedPR: BranchPRNode?,
        localMergedSet: Set<String>
    ) -> MergeStatus {
        if let pr = associatedPR, pr.state == "MERGED", targetNames.contains(pr.baseRefName) {
            return .merged
        }
        if localMergedSet.contains(branchName) {
            return .merged
        }
        if !localMergedSet.isEmpty {
            return .notMerged
        }
        if let pr = associatedPR {
            return pr.state == "MERGED" ? .unknown : .notMerged
        }
        return .unknown
    }

    private func mergedBranchNames(targets: [String], from branches: [LocalBranchInfo], repoPath: String) async -> Set<String> {
        var result: Set<String> = []
        for target in targets {
            guard branches.contains(where: { $0.name == target }) else { continue }
            for branch in branches {
                if await localGit.isMerged(branch: branch.name, into: target, repoPath: repoPath) {
                    result.insert(branch.name)
                }
            }
        }
        return result
    }

    /// Nonisolated helper to avoid Sendable issues with [String: Any] across actor boundaries.
    private nonisolated static func fetchBranchPage(
        client: GitHubGraphQLClient,
        owner: String,
        name: String,
        cursor: String?,
        token: String,
        endpoint: URL
    ) async throws -> BranchListResponse {
        var variables: [String: Any] = ["owner": owner, "name": name]
        if let cursor { variables["after"] = cursor }
        return try await client.execute(
            query: GitHubQueries.branchList,
            variables: variables,
            token: token,
            endpoint: endpoint
        )
    }
}
