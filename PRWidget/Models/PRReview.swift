import Foundation

struct PRReview: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let author: PRUser
    let state: ReviewState
    let submittedAt: Date?
}
