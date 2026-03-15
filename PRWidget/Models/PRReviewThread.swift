import Foundation

struct PRReviewThread: Identifiable, Sendable {
    let id: String
    let path: String
    let line: Int?
    let startLine: Int?
    let diffSide: DiffSide
    let isResolved: Bool
    let isOutdated: Bool
    var comments: [PRReviewComment]
}

struct PRReviewComment: Identifiable, Sendable {
    let id: String
    let author: PRUser
    let body: String
    let createdAt: Date
    let url: URL?
}

enum DiffSide: String, Sendable, Decodable {
    case LEFT, RIGHT
}
