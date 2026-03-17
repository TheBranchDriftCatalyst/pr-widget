import Foundation

extension Date {
    /// Parse a GitHub API ISO 8601 date string.
    /// Tries fractional seconds first, then plain ISO 8601, falling back to `.now`.
    static func parseGitHub(_ string: String) -> Date {
        GitHubDateParser.shared.parse(string)
    }
}

/// Shared pair of ISO 8601 formatters used for all GitHub date parsing.
/// Kept as a class so the formatters are allocated once and reused.
private final class GitHubDateParser: @unchecked Sendable {
    static let shared = GitHubDateParser()

    private let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    func parse(_ string: String) -> Date {
        withFractional.date(from: string) ?? standard.date(from: string) ?? .now
    }
}
