import Foundation

/// `UserDefaults` persistence for `Codable` types, stored as JSON data.
///
/// `PersistedCodable` serializes the value to JSON before writing and
/// deserializes on read. If decoding fails (e.g., due to a schema change),
/// ``load()`` silently returns the default value.
///
/// ## Usage
///
/// ```swift
/// struct AppConfig: Codable, Sendable {
///     var theme: String = "dark"
///     var columns: Int = 3
/// }
///
/// let config = PersistedCodable("app.config", default: AppConfig())
/// config.save(AppConfig(theme: "dark", columns: 4))
/// let loaded = config.load() // AppConfig(theme: "dark", columns: 4)
/// ```
///
/// - Warning: If you change the `Codable` schema in a breaking way, existing
///   stored data will fail to decode. Use ``DefaultsMigration`` to handle
///   key migrations, or ensure your type uses coding keys with defaults.
public struct PersistedCodable<Value: Codable & Sendable>: Sendable {
    /// The UserDefaults key.
    public let key: String

    /// The value returned by ``load()`` when no stored value exists or decoding fails.
    public let defaultValue: Value

    /// The UserDefaults suite to read from and write to.
    public nonisolated(unsafe) let suite: UserDefaults

    /// Creates a Codable persistence descriptor.
    /// - Parameters:
    ///   - key: The UserDefaults key.
    ///   - defaultValue: The fallback value when the key is absent or decoding fails.
    ///   - suite: The UserDefaults suite. Defaults to `.standard`.
    public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.suite = suite
    }

    /// Loads and decodes the stored value, or returns ``defaultValue`` if absent or on decode failure.
    /// - Returns: The decoded value or the default.
    public func load() -> Value {
        guard let data = suite.data(forKey: key),
              let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
            return defaultValue
        }
        return decoded
    }

    /// Encodes and saves a value to UserDefaults as JSON data.
    ///
    /// Does nothing if encoding fails.
    /// - Parameter value: The value to persist.
    public func save(_ value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        suite.set(data, forKey: key)
    }

    /// Removes the stored value from UserDefaults.
    ///
    /// After removal, the next call to ``load()`` returns ``defaultValue``.
    public func remove() {
        suite.removeObject(forKey: key)
    }
}
