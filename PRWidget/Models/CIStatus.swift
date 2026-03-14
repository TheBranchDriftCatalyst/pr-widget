import Foundation

enum CIStatus: String, Codable, Sendable {
    case success = "SUCCESS"
    case failure = "FAILURE"
    case pending = "PENDING"
    case error = "ERROR"
    case unknown = "UNKNOWN"
}
