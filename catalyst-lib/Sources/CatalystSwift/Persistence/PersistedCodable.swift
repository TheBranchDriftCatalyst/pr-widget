import Foundation

/// UserDefaults persistence for Codable types (stored as JSON Data).
public struct PersistedCodable<Value: Codable & Sendable>: Sendable {
    public let key: String
    public let defaultValue: Value
    public nonisolated(unsafe) let suite: UserDefaults

    public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.suite = suite
    }

    public func load() -> Value {
        guard let data = suite.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
            return defaultValue
        }
        return decoded
    }

    public func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        suite.set(data, forKey: key)
    }

    public func remove() {
        suite.removeObject(forKey: key)
    }
}
