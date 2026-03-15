import Foundation
import Security

/// Helpers for migrating UserDefaults keys and Keychain items between prefixes.
///
/// Use these when rebranding an app, changing bundle identifiers, or
/// reorganizing your key namespace. All methods are idempotent — safe to
/// call on every launch.
///
/// ## Usage
///
/// ```swift
/// // Migrate UserDefaults keys
/// DefaultsMigration.migratePrefix(
///     from: "PRWidget",
///     to: "com.catalyst.p-arr",
///     keys: ["showBadge", "refreshInterval"]
/// )
///
/// // Migrate a Keychain item
/// DefaultsMigration.migrateKeychainService(
///     from: "PRWidget",
///     to: "com.catalyst.p-arr",
///     account: "github-pat"
/// )
/// ```
public enum DefaultsMigration {

    /// Migrates UserDefaults keys from one prefix to another.
    ///
    /// For each key, constructs `"\(oldPrefix).\(key)"` and
    /// `"\(newPrefix).\(key)"`. Only migrates if the old key exists and the
    /// new key does not. The old key is removed after migration.
    ///
    /// - Parameters:
    ///   - oldPrefix: The original key prefix.
    ///   - newPrefix: The new key prefix.
    ///   - keys: The suffix portion of each key to migrate.
    ///   - defaults: The UserDefaults suite. Defaults to `.standard`.
    public static func migratePrefix(
        from oldPrefix: String,
        to newPrefix: String,
        keys: [String],
        in defaults: UserDefaults = .standard
    ) {
        for key in keys {
            let oldKey = "\(oldPrefix).\(key)"
            let newKey = "\(newPrefix).\(key)"
            guard defaults.object(forKey: oldKey) != nil,
                  defaults.object(forKey: newKey) == nil else { continue }
            let value = defaults.object(forKey: oldKey)
            defaults.set(value, forKey: newKey)
            defaults.removeObject(forKey: oldKey)
        }
    }

    /// Migrates a Keychain item from one service to another.
    ///
    /// Reads the secret from the old service, writes it to the new service,
    /// and deletes the old entry. Only migrates if the old item exists and
    /// the new one does not.
    ///
    /// - Parameters:
    ///   - oldService: The original Keychain service name.
    ///   - newService: The new Keychain service name.
    ///   - account: The Keychain account identifier.
    public static func migrateKeychainService(
        from oldService: String,
        to newService: String,
        account: String
    ) {
        let old = PersistedSecret(service: oldService, account: account)
        let new = PersistedSecret(service: newService, account: account)
        guard let value = old.load(), new.load() == nil else { return }
        new.save(value)
        old.delete()
    }
}
