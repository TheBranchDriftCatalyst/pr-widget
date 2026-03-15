import CryptoKit
import Foundation

actor GitHubGraphQLClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    private(set) var rateLimitRemaining: Int = 5000
    private(set) var rateLimitResetAt: Date?

    private var etagCache: [String: CachedResponse] = [:]

    private struct CachedResponse {
        let etag: String
        let data: Data
    }

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "PRWidget/0.1"]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder.github
    }

    private func cacheKey(query: String, variables: [String: Any]?, endpoint: URL) -> String {
        var input = query + endpoint.absoluteString
        if let variables,
           let data = try? JSONSerialization.data(withJSONObject: variables, options: .sortedKeys) {
            input += String(data: data, encoding: .utf8) ?? ""
        }
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func execute<T: Decodable>(
        query: String,
        variables: [String: Any]? = nil,
        token: String,
        endpoint: URL
    ) async throws -> T {
        let key = cacheKey(query: query, variables: variables, endpoint: endpoint)

        var body: [String: Any] = ["query": query]
        if let variables { body["variables"] = variables }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        if let cached = etagCache[key] {
            request.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
        }

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

        let responseData: Data
        switch httpResponse.statusCode {
        case 304:
            NSLog("[PArr] ETag cache hit (304) for GraphQL request")
            guard let cached = etagCache[key] else {
                throw APIError.httpError(statusCode: 304)
            }
            responseData = cached.data
        case 200:
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                etagCache[key] = CachedResponse(etag: etag, data: data)
                NSLog("[PArr] Cached ETag for GraphQL request")
            }
            responseData = data
        case 401: throw APIError.unauthorized
        case 403 where rateLimitRemaining == 0:
            throw APIError.rateLimited(resetAt: rateLimitResetAt)
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse GraphQL response envelope
        let envelope: GraphQLResponse<T>
        do {
            envelope = try decoder.decode(GraphQLResponse<T>.self, from: responseData)
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

    func fetchFileDiffs(
        owner: String,
        repo: String,
        number: Int,
        token: String
    ) async throws -> [RESTFileDiff] {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/pulls/\(number)/files?per_page=100"
        guard let url = URL(string: urlString) else {
            throw APIError.networkError(
                NSError(domain: "PRWidget", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            )
        }

        let key = urlString

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("PRWidget/0.1", forHTTPHeaderField: "User-Agent")

        if let cached = etagCache[key] {
            request.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.httpError(statusCode: 0)
        }

        let responseData: Data
        switch httpResponse.statusCode {
        case 304:
            NSLog("[PArr] ETag cache hit (304) for REST file diffs")
            guard let cached = etagCache[key] else {
                throw APIError.httpError(statusCode: 304)
            }
            responseData = cached.data
        case 200:
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                etagCache[key] = CachedResponse(etag: etag, data: data)
            }
            responseData = data
        case 401: throw APIError.unauthorized
        case 403:
            throw APIError.rateLimited(resetAt: nil)
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode([RESTFileDiff].self, from: responseData)
    }
}

private struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}
