import Foundation

/// Type-safe UserDefaults persistence descriptor.
public struct Persisted<Value: DefaultsStorable>: Sendable {
    public let key: String
    public let defaultValue: Value
    public nonisolated(unsafe) let suite: UserDefaults

    public init(_ key: String, default defaultValue: Value, suite: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.suite = suite
    }

    public func load() -> Value {
        Value.read(from: suite, forKey: key) ?? defaultValue
    }

    public func save(_ value: Value) {
        value.write(to: suite, forKey: key)
    }

    public func remove() {
        suite.removeObject(forKey: key)
    }
}

// MARK: - Set<String> convenience

extension Persisted where Value == [String] {
    public func loadSet() -> Set<String> {
        Set(load())
    }

    public func saveSet(_ value: Set<String>) {
        save(Array(value))
    }
}
