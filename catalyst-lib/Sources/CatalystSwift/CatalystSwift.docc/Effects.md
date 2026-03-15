# Effects

Visual effect modifiers that bring the cybersynthpunk aesthetic to life — glass surfaces, neon glows, shimmering loaders, and themed scrollbars.

## Overview

CatalystSwift provides a set of `ViewModifier` types and convenience extension methods on `View` for applying visual effects. All effects respect macOS accessibility settings: reduced transparency and reduced motion are handled automatically.

## Glass Card

The ``GlassCardModifier`` creates a frosted-glass card surface with a gradient background, subtle glass overlay, rounded corners, and a thin border stroke. When the user has enabled Reduce Transparency in System Settings, the overlay is removed and a solid card color is used instead.

```swift
VStack {
    Text("Dashboard")
        .font(Catalyst.heading())
    Text("Content here")
        .font(Catalyst.body())
}
.padding()
.glassCard()
```

## Neon Glow

The ``NeonGlowModifier`` applies a double-layered shadow in a neon accent color, producing a soft radiant glow effect. Disabled when Reduce Motion is on.

```swift
Image(systemName: "bolt.fill")
    .foregroundStyle(Catalyst.cyan)
    .neonGlow(Catalyst.cyan)

// Custom radius
Text("ALERT")
    .foregroundStyle(Catalyst.red)
    .neonGlow(Catalyst.red, radius: 12)
```

## Glow Divider

``GlowDivider`` is a standalone view that renders a thin horizontal line with a faint cyan glow beneath it. Use it as a section separator inside glass cards.

```swift
VStack {
    Text("Section A")
    GlowDivider()
    Text("Section B")
}
```

## Shimmer Loading

The ``ShimmerLoadingModifier`` overlays a sweeping gradient animation that moves left-to-right continuously. Ideal for skeleton loading states. Falls back to a static subtle overlay when Reduce Motion is enabled.

```swift
RoundedRectangle(cornerRadius: Catalyst.radiusMD)
    .fill(Catalyst.surface)
    .frame(height: 44)
    .shimmerLoading()
```

## Hover Glow

The ``HoverGlowModifier`` adds a subtle background highlight that appears when the cursor hovers over the view. Useful for interactive list rows and buttons.

```swift
HStack {
    Text("Pull Request #42")
    Spacer()
    Image(systemName: "chevron.right")
}
.padding()
.hoverGlow(Catalyst.cyan)
```

## Gradient Accent Stripe

``GradientAccentStripe`` is a 3pt-wide vertical stripe with a gradient fill and glow shadow. Commonly used as a leading accent on card rows to indicate category or status.

```swift
HStack(spacing: 0) {
    GradientAccentStripe(color: Catalyst.cyan)
    Text("Ready to merge")
        .padding(.horizontal, 12)
}
```

## Catalyst Tooltip

The ``CatalystTooltipModifier`` displays a themed tooltip above the view on hover. The tooltip uses the dark card style with a neon-tinted border and an arrow pointing down. Animates in with a spring transition (static opacity when Reduce Motion is on).

```swift
Button("Merge") { /* ... */ }
    .catalystTooltip("Merge this pull request")

// Custom accent color
Image(systemName: "exclamationmark.triangle")
    .catalystTooltip("Conflicts detected", accent: Catalyst.red)
```

## Themed Scrollbar

``CatalystScroller`` is a custom `NSScroller` subclass that renders a thin (6pt) cyan-tinted scrollbar knob on a transparent track. Apply it to any `ScrollView` using the `.catalystScrollbar()` modifier, which injects ``ScrollViewStyler`` into the view hierarchy.

```swift
ScrollView {
    VStack {
        ForEach(items) { item in
            Text(item.name)
        }
    }
}
.catalystScrollbar()
```

## Conditional Modifier

The `.if(_:transform:)` extension lets you conditionally apply any modifier:

```swift
Text("Status")
    .if(isActive) { $0.foregroundStyle(Catalyst.cyan) }
```

## Accessibility

All effects that involve animation or transparency check the appropriate environment values:

| Effect | Checks | Fallback |
|--------|--------|----------|
| Glass Card | `accessibilityReduceTransparency` | Solid card color |
| Neon Glow | `accessibilityReduceMotion` | No shadow |
| Shimmer | `accessibilityReduceMotion` | Static overlay |
| Tooltip | `accessibilityReduceMotion` | Opacity-only transition |
