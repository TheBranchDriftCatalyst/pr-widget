import Foundation

// MARK: - Enums

enum BranchLocation: Int, Sendable, CaseIterable, Comparable {
    case both = 0
    case local = 1
    case remote = 2

    static func < (lhs: BranchLocation, rhs: BranchLocation) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum MergeStatus: Int, Sendable, Comparable {
    case merged = 0
    case notMerged = 1
    case unknown = 2

    static func < (lhs: MergeStatus, rhs: MergeStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Tracked Repository (persisted)

struct TrackedRepository: Identifiable, Hashable, Codable, Sendable {
    let nameWithOwner: String
    let url: URL
    let accountID: UUID

    var id: String { nameWithOwner }
    var owner: String { String(nameWithOwner.split(separator: "/").first ?? "") }
    var name: String { String(nameWithOwner.split(separator: "/").last ?? "") }
}

// MARK: - Branch PR Info

struct BranchPRInfo: Sendable, Hashable {
    let number: Int
    let url: URL
    let state: String       // OPEN, MERGED, CLOSED
    let baseRefName: String
}

// MARK: - Branch Info (unified row)

struct BranchInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let repository: TrackedRepository
    let location: BranchLocation
    let associatedPR: BranchPRInfo?
    let mergedToDevelop: MergeStatus
    let mergedToMain: MergeStatus
    let lastCommitter: String
    let lastActivity: Date
    /// GitHub ref node ID for deleteRef mutation; nil for local-only branches.
    let refNodeID: String?
    /// Name of the repo's default branch (main, master, etc.)
    let defaultBranchName: String?
    /// Whether this is the current checked-out branch locally.
    let isCurrentLocal: Bool

    var repoName: String { repository.nameWithOwner }

    /// Sortable PR key: PR number (higher = first), 0 if no PR.
    var prSortKey: Int { associatedPR?.number ?? 0 }

    var lastActivityText: String {
        lastActivity.branchRelativeTimeString
    }

    var isDeletable: Bool {
        // Never delete default branch or develop
        let protected = Set([defaultBranchName, "main", "master", "develop", "development"].compactMap { $0 })
        return !protected.contains(name) && !isCurrentLocal
    }
}

// MARK: - Local Branch Info (from git)

struct LocalBranchInfo: Sendable {
    let name: String
    let lastCommitter: String
    let lastCommitDate: Date
    let isCurrent: Bool
}

// MARK: - Discovered Local Repo

struct DiscoveredRepo: Sendable {
    let nameWithOwner: String
    let localPath: String
}
