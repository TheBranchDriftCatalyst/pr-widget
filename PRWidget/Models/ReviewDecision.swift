import Foundation

enum ReviewDecision: String, Codable, Sendable {
    case changesRequested = "CHANGES_REQUESTED"
    case approved = "APPROVED"
    case reviewRequired = "REVIEW_REQUIRED"
}
