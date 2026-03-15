import Foundation

struct PRFileDiff: Identifiable, Sendable {
    let id: String
    let path: String
    let status: FileChangeType
    let additions: Int
    let deletions: Int
    let patch: String?
    var reviewThreads: [PRReviewThread]
}

enum FileChangeType: String, Sendable {
    case added, removed, modified, renamed, copied, changed, unchanged
}
