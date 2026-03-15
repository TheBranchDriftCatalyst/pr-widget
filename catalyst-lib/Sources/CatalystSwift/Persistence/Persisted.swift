import Foundation

/// A type-safe `UserDefaults` persistence descriptor for ``DefaultsStorable`` values.
///
/// `Persisted` wraps a key, default value, and optional suite into a reusable
/// descriptor. It does not hold state — call ``load()`` and ``save(_:)`` to
/// read and write.
///
/// ## Usage
///
/// ```swift
/// let showBadge = Persisted("app.showBadge", default: true)
///
/// // Read
/// let isShowing = showBadge.load()
///
/// // Write
/// showBadge.save(false)
///
/// // Remove (next load returns default)
/// showBadge.remove()
/// ```
///
/// ## Custom Suite
///
/// ```swift
/// let shared = UserDefaults(suiteName: "group.com.catalyst")!
/// let pref = Persisted("key", default: 42, suite: shared)
/// ```
public struct Persisted<Value: DefaultsStorable>: Sendable {
    /// The UserDefaults key.
    public let key: String

    /// The value returned by ``load()`` when no stored value exists.
    public let defaultValue: Value

    /// The UserDefaults suite to read from and write to.
    public nonisolated(unsafe) let suite: UserDefaults

    /// Creates a persistence descriptor.
    /// - Parameters:
    ///   - key: The UserDefaults key.
    ///   - defaultValue: The fallback value when the key is absent.
    ///   - suite: The UserDefaults suite. Defaults to `.standard`.
    public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.suite = suite
    }

    /// Loads the stored value, or returns ``defaultValue`` if absent.
    /// - Returns: The persisted value or the default.
    public func load() -> Value {
        Value.read(from: suite, forKey: key) ?? defaultValue
    }

    /// Saves a value to UserDefaults.
    /// - Parameter value: The value to persist.
    public func save(_ value: Value) {
        value.write(to: suite, forKey: key)
    }

    /// Removes the stored value from UserDefaults.
    ///
    /// After removal, the next call to ``load()`` returns ``defaultValue``.
    public func remove() {
        suite.removeObject(forKey: key)
    }
}

// MARK: - Set<String> convenience

extension Persisted where Value == [String] {
    /// Loads the stored string array as a `Set<String>`.
    /// - Returns: The persisted values as a set, or an empty set if absent.
    public func loadSet() -> Set<String> {
        Set(load())
    }

    /// Saves a `Set<String>` as a string array.
    /// - Parameter value: The set to persist.
    public func saveSet(_ value: Set<String>) {
        save(Array(value))
    }
}
