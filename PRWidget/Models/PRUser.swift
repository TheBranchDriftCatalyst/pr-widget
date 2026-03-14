import Foundation

struct PRUser: Identifiable, Hashable, Codable, Sendable {
    let login: String
    let avatarURL: URL?

    var id: String { login }
}
