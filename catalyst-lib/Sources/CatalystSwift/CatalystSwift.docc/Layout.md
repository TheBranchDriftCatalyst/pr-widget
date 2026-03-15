# Layout

Custom layout containers for flexible view arrangement.

## Overview

CatalystSwift provides ``FlowLayout``, a horizontal wrapping layout that automatically moves items to the next row when they exceed the available width. This is the same pattern as CSS `flex-wrap: wrap`.

## FlowLayout

``FlowLayout`` conforms to SwiftUI's `Layout` protocol and arranges its children left-to-right, wrapping to new rows as needed.

```swift
FlowLayout(spacing: 6) {
    ForEach(tags, id: \.self) { tag in
        Text(tag)
            .font(Catalyst.label())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Catalyst.cyan.opacity(0.15))
            .clipShape(.rect(cornerRadius: Catalyst.radiusSM))
    }
}
```

### Parameters

- `spacing` — The gap between items, both horizontally and vertically. Defaults to `4`.

### Behavior

- Items are laid out left-to-right in the proposed width
- When the next item would exceed the available width, a new row starts
- Row height is determined by the tallest item in that row
- The same `spacing` value is used for both horizontal gaps and vertical row gaps
- Returns a size that fits all rows tightly

### Common Use Cases

- Tag clouds and chip groups
- Badge lists
- Keyword displays
- Any collection of variably-sized elements that should wrap naturally
