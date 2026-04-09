import CryptoKit
import Foundation

actor GitHubGraphQLClient {
    /// Shared singleton instance for use by DashboardStore, ActionHandler, AccountSetupView, etc.
    static let shared = GitHubGraphQLClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private(set) var rateLimitRemaining: Int = 5000
    private(set) var rateLimitResetAt: Date?

    private var etagCache: [String: CachedEntry] = [:]

    /// Maximum number of ETag cache entries before eviction kicks in.
    private let maxCacheSize = 50

    /// Directory for cached response data on disk.
    private let cacheDirectory: URL

    /// Lightweight in-memory entry — response data lives on disk.
    private struct CachedEntry {
        let etag: String
        let filePath: URL
        var lastAccessed: Date

        func loadData() -> Data? {
            try? Data(contentsOf: filePath)
        }
    }

    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": "PRWidget/0.1"]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder.github

        // Use Caches directory — system can purge when disk is low
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = caches.appendingPathComponent("com.catalyst.p-arr.etag-cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
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

    // MARK: - Cache Eviction

    /// Evict the oldest cache entry (by lastAccessed) when cache exceeds maxCacheSize.
    private func evictCacheIfNeeded() {
        guard etagCache.count > maxCacheSize else { return }
        let oldest = etagCache.min { $0.value.lastAccessed < $1.value.lastAccessed }
        if let oldestKey = oldest?.key {
            if let entry = etagCache.removeValue(forKey: oldestKey) {
                try? FileManager.default.removeItem(at: entry.filePath)
            }
            NSLog("[PArr] Evicted oldest ETag cache entry (%d entries remain)", etagCache.count)
        }
    }

    /// Write response data to disk cache, returning the file URL.
    private func writeCacheFile(key: String, data: Data) -> URL {
        let file = cacheDirectory.appendingPathComponent(key)
        try? data.write(to: file, options: .atomic)
        return file
    }

    // MARK: - Retry Helpers

    /// Maximum number of retries for transient failures.
    private static let maxRetries = 2

    /// Base backoff intervals in seconds for each retry attempt.
    private static let backoffIntervals: [TimeInterval] = [1.0, 3.0]

    /// HTTP status codes that are safe to retry.
    private static let retryableStatusCodes: Set<Int> = [429, 502, 503]

    /// URLError codes that are safe to retry.
    private static let retryableURLErrorCodes: Set<URLError.Code> = [
        .timedOut,
        .networkConnectionLost,
    ]

    /// Determine backoff for a retry attempt, honoring Retry-After header for 429s.
    private func backoffDuration(attempt: Int, httpResponse: HTTPURLResponse?) -> TimeInterval {
        if let httpResponse, httpResponse.statusCode == 429,
           let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
           let seconds = TimeInterval(retryAfter) {
            return seconds
        }
        let index = min(attempt, Self.backoffIntervals.count - 1)
        return Self.backoffIntervals[index]
    }

    /// Perform a URLRequest with retry logic for transient errors.
    /// Returns (Data, HTTPURLResponse) on success, or throws after exhausting retries.
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?
        var lastHTTPResponse: HTTPURLResponse?

        for attempt in 0...Self.maxRetries {
            if attempt > 0 {
                let delay = backoffDuration(attempt: attempt - 1, httpResponse: lastHTTPResponse)
                NSLog("[PArr] Retrying request (attempt %d) after %.1fs backoff", attempt, delay)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch let error as URLError where Self.retryableURLErrorCodes.contains(error.code) {
                lastError = APIError.networkError(error)
                lastHTTPResponse = nil
                continue
            } catch {
                throw APIError.networkError(error)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.httpError(statusCode: 0)
            }

            if Self.retryableStatusCodes.contains(httpResponse.statusCode) {
                lastError = APIError.httpError(statusCode: httpResponse.statusCode)
                lastHTTPResponse = httpResponse
                continue
            }

            return (data, httpResponse)
        }

        throw lastError ?? APIError.httpError(statusCode: 0)
    }

    // MARK: - Execute (GraphQL)

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

        let (data, httpResponse) = try await performRequest(request)

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
            guard var cached = etagCache[key],
                  let diskData = cached.loadData() else {
                throw APIError.httpError(statusCode: 304)
            }
            cached.lastAccessed = Date()
            etagCache[key] = cached
            responseData = diskData
        case 200:
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                let file = writeCacheFile(key: key, data: data)
                etagCache[key] = CachedEntry(etag: etag, filePath: file, lastAccessed: Date())
                evictCacheIfNeeded()
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

    // MARK: - REST File Diffs

    /// Fetch file diffs for a PR via the REST API.
    /// - Parameter host: The GitHub host (e.g., "github.com" or "github.mycompany.com").
    ///   For GitHub Enterprise, uses `https://{host}/api/v3/repos/...`.
    ///   For cloud (github.com), uses `https://api.github.com/repos/...`.
    func fetchFileDiffs(
        owner: String,
        repo: String,
        number: Int,
        token: String,
        host: String = "github.com"
    ) async throws -> [RESTFileDiff] {
        let baseURL: String
        if host == "github.com" {
            baseURL = "https://api.github.com"
        } else {
            baseURL = "https://\(host)/api/v3"
        }
        let urlString = "\(baseURL)/repos/\(owner)/\(repo)/pulls/\(number)/files?per_page=100"

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

        let (data, httpResponse) = try await performRequest(request)

        let responseData: Data
        switch httpResponse.statusCode {
        case 304:
            NSLog("[PArr] ETag cache hit (304) for REST file diffs")
            guard var cached = etagCache[key],
                  let diskData = cached.loadData() else {
                throw APIError.httpError(statusCode: 304)
            }
            cached.lastAccessed = Date()
            etagCache[key] = cached
            responseData = diskData
        case 200:
            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                let file = writeCacheFile(key: key, data: data)
                etagCache[key] = CachedEntry(etag: etag, filePath: file, lastAccessed: Date())
                evictCacheIfNeeded()
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
