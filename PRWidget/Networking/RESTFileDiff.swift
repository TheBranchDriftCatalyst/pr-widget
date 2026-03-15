import Foundation

struct RESTFileDiff: Decodable, Sendable {
    let sha: String
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let patch: String?
}
