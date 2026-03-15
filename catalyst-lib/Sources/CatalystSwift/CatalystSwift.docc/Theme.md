# Theme

The Catalyst design token system — colors, typography, spacing, and animation values for a cohesive cybersynthpunk dark theme.

## Overview

All visual constants live in the ``Catalyst`` enum. This is a port of the catalyst-ui React/TypeScript design system into native Swift, ensuring pixel-perfect consistency across web and macOS apps.

The theme is dark-first with neon accent colors inspired by cyberpunk aesthetics. Every token is a `static` property or function on ``Catalyst``, so there is no instance to create.

## Color Tokens

### Core Surfaces

| Token | Hex | Usage |
|-------|-----|-------|
| ``Catalyst/background`` | `#0a0a0f` | App background, deepest layer |
| ``Catalyst/card`` | `#16161d` | Card backgrounds, elevated surfaces |
| ``Catalyst/surface`` | `#1e1e24` | Interactive surface backgrounds |
| ``Catalyst/border`` | `#27272a` | Borders, dividers, separators |

### Text Hierarchy

| Token | Hex | Usage |
|-------|-----|-------|
| ``Catalyst/foreground`` | `#e4e4e7` | Primary text, headings |
| ``Catalyst/muted`` | `#a1a1aa` | Secondary text, descriptions |
| ``Catalyst/subtle`` | `#66666f` | Tertiary text, timestamps, hints |

### Neon Accents

| Token | Hex | Usage |
|-------|-----|-------|
| ``Catalyst/cyan`` | `#00fcd6` | Primary accent, success states, links |
| ``Catalyst/magenta`` | `#c026d3` | Secondary accent, badges |
| ``Catalyst/pink`` | `#ff6ec7` | Tertiary accent, highlights |
| ``Catalyst/blue`` | `#00d4ff` | Information, pending states |
| ``Catalyst/red`` | `#ff2975` | Errors, destructive actions |
| ``Catalyst/yellow`` | `#fbbf24` | Warnings, keyboard shortcuts |

### Semantic Aliases

| Token | Maps to | Usage |
|-------|---------|-------|
| ``Catalyst/success`` | cyan | Positive outcomes |
| ``Catalyst/failure`` | red | Negative outcomes |
| ``Catalyst/warning`` | yellow | Caution states |
| ``Catalyst/pending`` | blue | In-progress states |
| ``Catalyst/destructive`` | red | Destructive actions |

## Typography

The type scale uses system fonts with monospaced design for most levels. Sizes decrease in 1pt increments from display (15pt) to nano (8pt).

| Token | Size | Weight | Design |
|-------|------|--------|--------|
| `display()` | 15pt | Semibold | Default |
| `heading()` | 14pt | Medium | Default |
| `subheading()` | 13pt | Bold | Monospaced |
| `body()` | 12pt | Regular | Monospaced |
| `caption()` | 11pt | Medium | Monospaced |
| `label()` | 10pt | Bold | Monospaced |
| `micro()` | 9pt | Bold | Monospaced |
| `nano()` | 8pt | Bold | Monospaced |

For scale-aware typography that respects user preferences, use ``CatalystFontToken`` with the `.catalystFont(_:)` modifier. See <doc:UIScale> for details.

## Spacing Scale

Based on a 4pt grid:

| Token | Value | Usage |
|-------|-------|-------|
| ``Catalyst/spaceXS`` | 2pt | Tight gaps between related elements |
| ``Catalyst/spaceSM`` | 4pt | Small internal padding |
| ``Catalyst/spaceMD`` | 8pt | Standard spacing, default padding |
| ``Catalyst/spaceLG`` | 12pt | Section spacing |
| ``Catalyst/spaceXL`` | 16pt | Large gaps, container padding |
| ``Catalyst/space2XL`` | 24pt | Major section breaks |

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| ``Catalyst/radiusSM`` | 3pt | Small elements, badges |
| ``Catalyst/radiusMD`` | 8pt | Cards, buttons, inputs |
| ``Catalyst/radiusFull`` | 999pt | Fully rounded (pills, circles) |

## Animation Durations

| Token | Value | Usage |
|-------|-------|-------|
| ``Catalyst/animInstant`` | 0.1s | Micro-interactions, hovers |
| ``Catalyst/animFast`` | 0.15s | Quick transitions |
| ``Catalyst/animNormal`` | 0.25s | Standard transitions |
| ``Catalyst/animSlow`` | 0.5s | Deliberate animations |
| ``Catalyst/animPulse`` | 3.0s | Slow repeating animations |

## Gradients

```swift
// Single-color neon gradient (leading full -> trailing faded)
Catalyst.neonGradient(Catalyst.cyan)

// Card background gradient
Catalyst.cardGradient
```

## Usage Example

```swift
VStack(spacing: Catalyst.spaceLG) {
    Text("SYSTEM STATUS")
        .font(Catalyst.label())
        .tracking(Catalyst.trackingLabel)
        .foregroundStyle(Catalyst.cyan)

    Text("All systems operational")
        .font(Catalyst.body())
        .foregroundStyle(Catalyst.foreground)

    Text("Last checked 2 minutes ago")
        .font(Catalyst.caption())
        .foregroundStyle(Catalyst.subtle)
}
.padding(Catalyst.spaceXL)
.background(Catalyst.cardGradient)
.clipShape(.rect(cornerRadius: Catalyst.radiusMD))
```
