import Foundation
import Security

/// Helpers for migrating UserDefaults keys and Keychain items between prefixes.
public enum DefaultsMigration {

    /// Migrate UserDefaults keys from one prefix to another.
    /// Only migrates if the old key exists and the new key does not.
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

    /// Migrate a Keychain item from one service to another.
    /// Only migrates if the old item exists and the new one does not.
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
