import Foundation

struct RESTFileDiff: Decodable, Sendable {
    let sha: String
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let patch: String?
}

struct RESTReviewComment: Decodable, Sendable {
    let nodeId: String
    let body: String
    let user: User?
    let createdAt: Date
    let htmlUrl: String?

    struct User: Decodable, Sendable {
        let login: String
        let avatarUrl: String?

        enum CodingKeys: String, CodingKey {
            case login
            case avatarUrl = "avatar_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case nodeId = "node_id"
        case body
        case user
        case createdAt = "created_at"
        case htmlUrl = "html_url"
    }
}
