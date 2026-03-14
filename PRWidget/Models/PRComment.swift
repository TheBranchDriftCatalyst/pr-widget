import Foundation

struct PRComment: Identifiable, Hashable, Sendable {
    let id: String
    let author: PRUser
    let body: String
    let createdAt: Date
    let url: URL?
    let isMinimized: Bool
}
