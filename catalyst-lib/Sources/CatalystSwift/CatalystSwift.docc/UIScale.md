# UIScale

Dynamic text scaling system that lets users adjust font sizes across the entire app from a single slider.

## Overview

The UIScale system propagates a scale factor through the SwiftUI environment. Every text element that uses the scale-aware modifiers or views will resize proportionally when the user adjusts the slider.

The system consists of four parts:

1. **Environment key** — ``CatalystScaleKey`` stores the scale factor (default `1.0`)
2. **Font tokens** — ``CatalystFontToken`` defines the type scale with size, weight, and design
3. **Scaled views** — ``CText`` and ``CLabel`` apply the scale automatically
4. **Settings control** — ``UIScaleSlider`` provides the UI for adjustment

## Setting Up the Scale

Inject the scale factor at the top of your view hierarchy:

```swift
@State private var uiScale: CGFloat = 1.0

var body: some View {
    ContentView()
        .environment(\.catalystScale, uiScale)
}
```

Persist the user's choice across launches:

```swift
let scalePref = Persisted("app.uiScale", default: 1.0)

// On load
uiScale = scalePref.load()

// On change
scalePref.save(uiScale)
```

## Using Font Tokens

The preferred way to apply scaled fonts is through ``CatalystFontToken``:

```swift
Text("Dashboard")
    .catalystFont(.heading)

Text("12 open PRs")
    .catalystFont(.body)

Text("Updated 2m ago")
    .catalystFont(.caption)
```

The `.catalystFont(_:)` modifier reads `catalystScale` from the environment and multiplies it with the token's base size.

## Scale-Aware Text Views

For convenience, ``CText`` and ``CLabel`` wrap SwiftUI's `Text` and `Label` with automatic scaling:

```swift
// Equivalent to Text("Hello").catalystFont(.body)
CText("Hello")

// Custom size and weight
CText("Status", size: 14, weight: .bold)

// With system image
CLabel("Merge", systemImage: "arrow.merge")
```

## Custom Font Sizes

For one-off sizes that still respect the scale, use ``ScaledFontModifier``:

```swift
Text("Custom sized")
    .scaledFont(size: 18, weight: .bold, design: .monospaced)
```

## Adding the Scale Slider

Place ``UIScaleSlider`` in your settings view:

```swift
struct SettingsView: View {
    @Binding var scale: CGFloat

    var body: some View {
        VStack {
            UIScaleSlider(scale: $scale)
            // other settings...
        }
    }
}
```

The slider ranges from 80% to 140% in 5% steps, with a Reset button that appears when the value differs from 100%. A live preview line shows the current scale applied to sample text.

## Token Reference

| Token | Base Size | Weight | Design |
|-------|-----------|--------|--------|
| `.display` | 15pt | Semibold | Default |
| `.heading` | 14pt | Medium | Default |
| `.subheading` | 13pt | Bold | Monospaced |
| `.body` | 12pt | Regular | Monospaced |
| `.caption` | 11pt | Medium | Monospaced |
| `.label` | 10pt | Bold | Monospaced |
| `.micro` | 9pt | Bold | Monospaced |
| `.nano` | 8pt | Bold | Monospaced |

At scale `1.0`, these match the static ``Catalyst`` type scale functions exactly. At scale `1.2`, a `.body` token renders at 14.4pt instead of 12pt.
