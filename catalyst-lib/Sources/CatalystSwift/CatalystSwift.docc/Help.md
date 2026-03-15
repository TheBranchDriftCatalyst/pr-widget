# Help

A lightweight help-tip system for displaying contextual hints and keyboard shortcuts throughout your app.

## Overview

The Help module provides three components:

- ``HelpTip`` — a data model representing a single tip with title, description, category, icon, and optional keyboard shortcut
- ``HelpBadgeModifier`` — a view modifier that attaches a tooltip (and optional "?" badge) to any view
- ``HelpSettingsView`` — a full-page view that renders all tips grouped by category

## Defining Tips

Create a central collection of tips for your app:

```swift
enum AppTips {
    static let toggleDashboard = HelpTip(
        id: "toggle-dashboard",
        category: "Navigation",
        title: "Toggle Dashboard",
        description: "Show or hide the floating dashboard window.",
        shortcut: "Cmd+Shift+Opt+P",
        icon: "rectangle.on.rectangle"
    )

    static let refreshPRs = HelpTip(
        id: "refresh-prs",
        category: "Actions",
        title: "Refresh Pull Requests",
        description: "Fetch the latest PR data from GitHub.",
        shortcut: "Cmd+R",
        icon: "arrow.clockwise"
    )

    static let all: [HelpTip] = [toggleDashboard, refreshPRs]
}
```

## Attaching Tips to Views

Use the `.helpTip(_:showBadge:)` modifier to add a native macOS tooltip:

```swift
Button("Toggle") { /* ... */ }
    .helpTip(AppTips.toggleDashboard)
```

To also show a small "?" badge indicator in the top-right corner:

```swift
Image(systemName: "gear")
    .helpTip(AppTips.settings, showBadge: true)
```

## Showing All Tips

Use ``HelpSettingsView`` to render a full help reference, typically in a settings tab:

```swift
struct SettingsView: View {
    var body: some View {
        TabView {
            HelpSettingsView(tips: AppTips.all)
                .tabItem { Label("Help", systemImage: "questionmark.circle") }
        }
    }
}
```

Tips are automatically grouped by their `category` string, with categories appearing in first-occurrence order. Each row shows the icon, title, description, and keyboard shortcut (if present). Shortcuts are highlighted in ``Catalyst/yellow``.
