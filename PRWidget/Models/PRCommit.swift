import Foundation

struct PRCommit: Identifiable, Hashable, Sendable {
    let id: String
    let sha: String
    let message: String
    let author: PRUser?
    let url: URL?
}
