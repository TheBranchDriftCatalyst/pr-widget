import Foundation

enum GitHubHostType: String, Codable, Sendable {
    case cloud
    case enterprise
}

struct GitHubAccount: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var username: String
    var host: String
    var hostType: GitHubHostType
    var avatarURL: URL?

    var graphQLEndpoint: URL {
        switch hostType {
        case .cloud:
            URL(string: "https://api.github.com/graphql")!
        case .enterprise:
            URL(string: "https://\(host)/api/graphql")!
        }
    }

    var displayName: String {
        switch hostType {
        case .cloud: "\(username) (github.com)"
        case .enterprise: "\(username) (\(host))"
        }
    }

    init(id: UUID = UUID(), username: String, host: String = "github.com", hostType: GitHubHostType = .cloud, avatarURL: URL? = nil) {
        self.id = id
        self.username = username
        self.host = host
        self.hostType = hostType
        self.avatarURL = avatarURL
    }
}
