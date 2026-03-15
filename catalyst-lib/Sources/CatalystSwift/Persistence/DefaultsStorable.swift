import Foundation

/// Protocol for types that can be stored in UserDefaults.
public protocol DefaultsStorable: Sendable {
    static func read(from defaults: UserDefaults, forKey key: String) -> Self?
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
