import Foundation

/// A protocol for types that can be read from and written to `UserDefaults`.
///
/// Conform custom types to this protocol to use them with ``Persisted``.
/// Out-of-the-box conformances are provided for `Bool`, `String`, `Int`,
/// `Double`, `Data`, `Date`, and `[String]`.
///
/// ## Usage
///
/// ```swift
/// extension URL: DefaultsStorable {
///     public static func read(from defaults: UserDefaults, forKey key: String) -> URL? {
///         defaults.url(forKey: key)
///     }
///
///     public func write(to defaults: UserDefaults, forKey key: String) {
///         defaults.set(self, forKey: key)
///     }
/// }
/// ```
public protocol DefaultsStorable: Sendable {
    /// Reads a value from the given `UserDefaults` suite.
    /// - Parameters:
    ///   - defaults: The UserDefaults suite to read from.
    ///   - key: The key to look up.
    /// - Returns: The stored value, or `nil` if not found.
    static func read(from defaults: UserDefaults, forKey key: String) -> Self?

    /// Writes this value to the given `UserDefaults` suite.
    /// - Parameters:
    ///   - defaults: The UserDefaults suite to write to.
    ///   - key: The key to store under.
    func write(to defaults: UserDefaults, forKey key: String)
}

extension Bool: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> Bool? {
        defaults.object(forKey: key) != nil ? defaults.bool(forKey: key) : nil
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension String: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Int: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> Int? {
        defaults.object(forKey: key) != nil ? defaults.integer(forKey: key) : nil
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Double: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> Double? {
        defaults.object(forKey: key) != nil ? defaults.double(forKey: key) : nil
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Data: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Date: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Array: DefaultsStorable where Element == String {
    public static func read(from defaults: UserDefaults, forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}
