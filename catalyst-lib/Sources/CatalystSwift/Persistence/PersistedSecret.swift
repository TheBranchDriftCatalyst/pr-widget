import Foundation
import Security

/// Keychain-backed persistence for sensitive strings.
///
/// `PersistedSecret` stores and retrieves a single string value from the
/// macOS Keychain, identified by a service name and account. Use this for
/// API tokens, passwords, and other secrets that should not be stored in
/// UserDefaults.
///
/// ## Usage
///
/// ```swift
/// let token = PersistedSecret(
///     service: "com.catalyst.p-arr",
///     account: "github-pat"
/// )
///
/// // Save
/// token.save("ghp_xxxxxxxxxxxx")
///
/// // Load (nil if not found)
/// if let pat = token.load() {
///     print("Token: \(pat)")
/// }
///
/// // Delete
/// token.delete()
/// ```
///
/// - Important: ``save(_:)`` calls ``delete()`` first to avoid duplicate
///   Keychain entries. This is safe to call repeatedly.
public struct PersistedSecret: Sendable {
    /// The Keychain service identifier (typically your bundle ID).
    public let service: String

    /// The Keychain account name (identifies what the secret is for).
    public let account: String

    /// Creates a Keychain persistence descriptor.
    /// - Parameters:
    ///   - service: The Keychain service name (e.g., your bundle identifier).
    ///   - account: The account key (e.g., `"github-pat"`).
    public init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    /// Loads the secret string from the Keychain.
    /// - Returns: The stored string, or `nil` if not found.
    public func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Saves a string to the Keychain.
    ///
    /// Deletes any existing entry first to prevent duplicates.
    /// - Parameter value: The secret string to store.
    public func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Deletes the secret from the Keychain.
    public func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
