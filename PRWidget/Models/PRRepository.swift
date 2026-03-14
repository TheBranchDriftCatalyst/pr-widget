import Foundation

struct PRRepository: Hashable, Codable, Sendable {
    let nameWithOwner: String
    let url: URL
}
