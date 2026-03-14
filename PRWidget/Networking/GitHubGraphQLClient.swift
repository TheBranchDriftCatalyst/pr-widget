import Foundation

actor GitHubGraphQLClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    private(set) var rateLimitRemaining: Int = 5000
    private(set) var rateLimitResetAt: Date?

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "PRWidget/0.1"]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder.github
    }

    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        token: String,
        endpoint: URL
    ) async throws -> T {
        var body: [String: Any] = ["query": query]
        if let variables { body["variables"] = variables }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.httpError(statusCode: 0)
        }

        // Track rate limit
        if let remaining = httpResponse.value(forHTTPHeaderField: "x-ratelimit-remaining") {
            rateLimitRemaining = Int(remaining) ?? rateLimitRemaining
        }
        if let resetStr = httpResponse.value(forHTTPHeaderField: "x-ratelimit-reset"),
           let resetEpoch = TimeInterval(resetStr) {
            rateLimitResetAt = Date(timeIntervalSince1970: resetEpoch)
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw APIError.unauthorized
        case 403 where rateLimitRemaining == 0:
            throw APIError.rateLimited(resetAt: rateLimitResetAt)
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse GraphQL response envelope
        let envelope: GraphQLResponse<T>
        do {
            envelope = try decoder.decode(GraphQLResponse<T>.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }

        if let errors = envelope.errors, !errors.isEmpty {
            throw APIError.graphQLErrors(errors)
        }

        guard let result = envelope.data else {
            throw APIError.decodingError(
                NSError(domain: "PRWidget", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])
            )
        }

        return result
    }
}

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}
