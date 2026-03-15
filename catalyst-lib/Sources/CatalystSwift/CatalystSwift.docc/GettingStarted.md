# Getting Started with CatalystSwift

Set up CatalystSwift in your macOS app and start using the design system.

## Overview

CatalystSwift is a Swift package that provides design tokens, visual effects, persistence wrappers, and UI components for Catalyst macOS apps. This guide walks you through setup and basic usage.

## Add the Dependency

CatalystSwift lives as a local package alongside your app. Add it to your `Package.swift`:

```swift
let package = Package(
    name: "YourApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../catalyst-lib"),
    ],
    targets: [
        .executableTarget(
            name: "YourApp",
            dependencies: ["CatalystSwift"]
        ),
    ]
)
```

Then import it in any Swift file:

```swift
import CatalystSwift
```

## Apply the Theme

The ``Catalyst`` enum is your single source of truth for all design tokens.

### Colors

```swift
Text("Status: Online")
    .foregroundStyle(Catalyst.cyan)

VStack {
    // ...
}
.background(Catalyst.background)
```

### Typography

Use the type scale functions for consistent sizing:

```swift
Text("Dashboard")
    .font(Catalyst.heading())

Text("12 pull requests")
    .font(Catalyst.caption())
```

For dynamic text scaling that respects user preferences, use ``CatalystFontToken``:

```swift
Text("Scales with user preference")
    .catalystFont(.body)
```

### Spacing

All spacing uses a 4pt base unit:

```swift
VStack(spacing: Catalyst.spaceMD) {
    Text("First item")
    Text("Second item")
}
.padding(Catalyst.spaceXL)
```

## Add Visual Effects

CatalystSwift provides view modifiers for the cybersynthpunk aesthetic:

```swift
VStack {
    Text("Glass Card")
        .font(Catalyst.heading())
    Text("With frosted glass background")
        .font(Catalyst.body())
}
.padding()
.glassCard()
```

Add neon glow to interactive elements:

```swift
Image(systemName: "star.fill")
    .foregroundStyle(Catalyst.cyan)
    .neonGlow(Catalyst.cyan)
```

Show loading states with shimmer:

```swift
RoundedRectangle(cornerRadius: 8)
    .fill(Catalyst.surface)
    .shimmerLoading()
```

## Persist User Settings

Use the persistence wrappers for type-safe storage:

```swift
// Simple values in UserDefaults
let showNotifications = Persisted("app.showNotifications", default: true)
showNotifications.save(false)
let value = showNotifications.load() // false

// Complex Codable types
let config = PersistedCodable("app.config", default: AppConfig())
config.save(myConfig)

// Secrets in the Keychain
let token = PersistedSecret(service: "com.catalyst.myapp", account: "github-token")
token.save("ghp_abc123...")
```

## Next Steps

- <doc:Theme> for the complete color and typography reference
- <doc:Effects> for all visual effect modifiers
- <doc:UIScale> for the dynamic text scaling system
- <doc:Persistence> for the full persistence API and migration guide
