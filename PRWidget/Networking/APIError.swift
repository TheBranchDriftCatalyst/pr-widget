import Foundation

enum APIError: LocalizedError {
    case noToken
    case httpError(statusCode: Int)
    case graphQLErrors([GraphQLError])
    case decodingError(Error)
    case networkError(Error)
    case rateLimited(resetAt: Date?)
    case unauthorized
    case notModified

    var errorDescription: String? {
        switch self {
        case .noToken:
            "No authentication token found"
        case .httpError(let code):
            "HTTP error \(code)"
        case .graphQLErrors(let errors):
            errors.map(\.message).joined(separator: "; ")
        case .decodingError(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .rateLimited(let resetAt):
            if let resetAt {
                "Rate limited. Resets at \(resetAt.formatted(date: .omitted, time: .shortened))"
            } else {
                "Rate limited. Please wait."
            }
        case .unauthorized:
            "Authentication failed. Check your token."
        case .notModified:
            "Not modified (304)"
        }
    }
}

struct GraphQLError: Decodable, Sendable {
    let message: String
    let type: String?
    // Note: `path` intentionally omitted — GitHub sends mixed arrays (strings + ints)
    // which don't decode to [String]. The field is not displayed anywhere.
}
