import Foundation

struct PRLabel: Identifiable, Hashable, Codable, Sendable {
    let nodeId: String
    let name: String
    let color: String
    let description: String?

    var id: String { nodeId }
}
