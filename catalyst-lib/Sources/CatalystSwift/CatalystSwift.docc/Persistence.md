# Persistence

Type-safe wrappers for UserDefaults and Keychain storage, with migration utilities for evolving your data schema.

## Overview

CatalystSwift provides three persistence types, each suited to a different kind of data:

| Type | Backing Store | Use Case |
|------|--------------|----------|
| ``Persisted`` | UserDefaults | Primitive settings (Bool, String, Int, Double, Data, Date, [String]) |
| ``PersistedCodable`` | UserDefaults (JSON) | Complex Codable structures |
| ``PersistedSecret`` | macOS Keychain | API tokens, passwords, sensitive strings |

All three follow the same pattern: declare a descriptor, then call `load()`, `save(_:)`, and `remove()`/`delete()`.

## Persisted (UserDefaults)

``Persisted`` stores values that conform to ``DefaultsStorable``. Out of the box, this includes `Bool`, `String`, `Int`, `Double`, `Data`, `Date`, and `[String]`.

```swift
// Declare
let showBadge = Persisted("app.showBadge", default: true)
let refreshInterval = Persisted("app.refreshInterval", default: 300)
let username = Persisted("app.username", default: "")

// Read
let isShowing = showBadge.load()

// Write
showBadge.save(false)

// Remove (reverts to default on next load)
showBadge.remove()
```

### String Sets

For storing `Set<String>`, use the convenience methods on `Persisted<[String]>`:

```swift
let hiddenRepos = Persisted("app.hiddenRepos", default: [String]())
let current: Set<String> = hiddenRepos.loadSet()
hiddenRepos.saveSet(current.union(["new-repo"]))
```

### Custom Suite

Pass a custom `UserDefaults` suite for app groups or testing:

```swift
let shared = UserDefaults(suiteName: "group.com.catalyst.shared")!
let pref = Persisted("pref.key", default: true, suite: shared)
```

## PersistedCodable

``PersistedCodable`` serializes any `Codable & Sendable` type to JSON and stores the raw data in UserDefaults. Use this for structured configuration objects.

```swift
struct AppConfig: Codable, Sendable {
    var theme: String = "dark"
    var columns: Int = 3
}

let config = PersistedCodable("app.config", default: AppConfig())
config.save(AppConfig(theme: "dark", columns: 4))
let loaded = config.load()
```

- Note: If decoding fails (e.g., the schema changed), `load()` silently returns the default value. Plan migrations for breaking schema changes.

## PersistedSecret (Keychain)

``PersistedSecret`` stores sensitive strings in the macOS Keychain, identified by a service name and account.

```swift
let token = PersistedSecret(
    service: "com.catalyst.p-arr",
    account: "github-pat"
)

// Save
token.save("ghp_xxxxxxxxxxxx")

// Load (nil if not found)
if let pat = token.load() {
    print("Token found")
}

// Delete
token.delete()
```

- Important: `save(_:)` calls `delete()` first to avoid duplicates — this is safe to call repeatedly.

## DefaultsStorable Protocol

To support additional types with ``Persisted``, conform them to ``DefaultsStorable``:

```swift
extension URL: DefaultsStorable {
    public static func read(from defaults: UserDefaults, forKey key: String) -> URL? {
        defaults.url(forKey: key)
    }

    public func write(to defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}
```

Built-in conformances: `Bool`, `String`, `Int`, `Double`, `Data`, `Date`, `[String]`.

## Migrations

``DefaultsMigration`` provides helpers for renaming key prefixes and moving Keychain items between services. These are useful when rebranding an app or changing its bundle identifier.

### Migrating UserDefaults Keys

```swift
DefaultsMigration.migratePrefix(
    from: "PRWidget",
    to: "com.catalyst.p-arr",
    keys: ["showBadge", "refreshInterval", "hiddenRepos"]
)
```

This moves `PRWidget.showBadge` to `com.catalyst.p-arr.showBadge`, etc. Only migrates if the old key exists and the new key does not — safe to call on every launch.

### Migrating Keychain Items

```swift
DefaultsMigration.migrateKeychainService(
    from: "PRWidget",
    to: "com.catalyst.p-arr",
    account: "github-pat"
)
```

Reads the secret from the old service, writes it to the new service, and deletes the old entry.

## Best Practices

1. **Declare descriptors as constants** at the top of your file or in a dedicated `Preferences` enum
2. **Use semantic key prefixes** like `"com.catalyst.p-arr.showBadge"` to avoid collisions
3. **Run migrations early** in your app lifecycle (e.g., in `AppDelegate.applicationDidFinishLaunching`)
4. **Use `PersistedSecret` for anything sensitive** — never store tokens in UserDefaults
5. **Prefer `Persisted` over `PersistedCodable`** for simple types — it avoids JSON encoding overhead
