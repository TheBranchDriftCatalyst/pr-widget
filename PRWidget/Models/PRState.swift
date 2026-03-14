import Foundation

enum PRState: String, Codable, Sendable {
    case open = "OPEN"
    case closed = "CLOSED"
    case merged = "MERGED"
}
