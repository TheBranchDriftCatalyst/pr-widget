# ``CatalystSwift``

A shared Swift library for the Catalyst ecosystem of macOS apps. Dark-themed design tokens, visual effects, persistence wrappers, and UI components — built for cybersynthpunk aesthetics.

## Overview

CatalystSwift provides the foundational layer for Catalyst macOS applications. Every color, font, spacing value, and visual effect flows from a single source of truth, ensuring a cohesive dark-mode experience across the entire app family.

```
┌──────────────────────────────────────────────┐
│              CatalystSwift                    │
│                                               │
│  ┌─────────┐  ┌──────────┐  ┌─────────────┐  │
│  │  Theme   │  │ Effects  │  │  UIScale    │  │
│  │ (tokens) │  │ (visual) │  │ (dynamic)   │  │
│  └────┬─────┘  └────┬─────┘  └──────┬──────┘  │
│       │              │               │         │
│  ┌────┴──────────────┴───────────────┴──────┐  │
│  │            Persistence Layer             │  │
│  │  UserDefaults · Keychain · Migrations    │  │
│  └──────────────────────────────────────────┘  │
│                                               │
│  ┌──────────┐  ┌───────────┐  ┌───────────┐  │
│  │ Changelog│  │   Help    │  │  Updates   │  │
│  │ (parser) │  │ (tips UI) │  │ (brew)     │  │
│  └──────────┘  └───────────┘  └───────────┘  │
│                                               │
│  ┌──────────┐  ┌───────────┐                  │
│  │  Layout  │  │Extensions │                  │
│  │ (flow)   │  │ (hex,ver) │                  │
│  └──────────┘  └───────────┘                  │
└──────────────────────────────────────────────┘
```

## Getting Started

Add CatalystSwift as a local package dependency in your `Package.swift`:

```swift
dependencies: [
    .package(path: "../catalyst-lib"),
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["CatalystSwift"]
)
```

Import and use:

```swift
import CatalystSwift

struct ContentView: View {
    var body: some View {
        Text("Hello, Catalyst")
            .font(Catalyst.heading())
            .foregroundStyle(Catalyst.cyan)
            .padding(Catalyst.spaceMD)
            .glassCard()
    }
}
```

For a step-by-step walkthrough, see <doc:GettingStarted>.

## Topics

### Essentials

- <doc:GettingStarted>

### Theme System

- <doc:Theme>
- ``Catalyst``

### Visual Effects

- <doc:Effects>
- ``GlassCardModifier``
- ``NeonGlowModifier``
- ``ShimmerLoadingModifier``
- ``HoverGlowModifier``
- ``GlowDivider``
- ``GradientAccentStripe``
- ``CatalystTooltipModifier``

### Dynamic Text Scaling

- <doc:UIScale>
- ``CatalystFontToken``
- ``CatalystFontModifier``
- ``ScaledFontModifier``
- ``CText``
- ``CLabel``
- ``UIScaleSlider``
- ``CatalystScaleKey``

### Persistence

- <doc:Persistence>
- ``Persisted``
- ``PersistedCodable``
- ``PersistedSecret``
- ``DefaultsStorable``
- ``DefaultsMigration``

### Changelog

- <doc:Changelog>
- ``ChangelogParser``
- ``ChangelogView``
- ``ChangelogRelease``
- ``ChangelogSection``
- ``ChangelogEntry``

### Help System

- <doc:Help>
- ``HelpTip``
- ``HelpBadgeModifier``
- ``HelpSettingsView``

### Layout

- <doc:Layout>
- ``FlowLayout``

### Self-Update

- <doc:Updates>
- ``BrewSelfUpdater``
- ``BrewUpdateView``
- ``BrewUpdateError``

### Extensions

- ``Swift/Bundle``
- ``SwiftUI/Color``

### Scrollbar Theming

- ``CatalystScroller``
- ``ScrollViewStyler``
