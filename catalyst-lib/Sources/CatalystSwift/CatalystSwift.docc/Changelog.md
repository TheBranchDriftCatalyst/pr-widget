# Changelog

Parse and display Keep a Changelog / git-cliff markdown files as styled, expandable release cards.

## Overview

The Changelog module has two parts:

- ``ChangelogParser`` — a stateless parser that converts markdown into structured ``ChangelogRelease`` models
- ``ChangelogView`` — a SwiftUI view that renders releases as expandable glass cards

## Parsing a Changelog

``ChangelogParser`` handles the standard [Keep a Changelog](https://keepachangelog.com) format, including git-cliff output:

```markdown
## [0.4.0] - 2025-01-15

### Added
- **dashboard**: New team view for PR assignments
- Real-time status polling

### Fixed
- **auth**: Token refresh loop on expired PATs
```

Parse it:

```swift
let releases = ChangelogParser.parse(markdownString)
```

Or load directly from a bundle resource:

```swift
let releases = ChangelogParser.fromBundle()
```

This looks for `CHANGELOG.md` in the main bundle.

### Data Model

Each ``ChangelogRelease`` contains a version string, optional date, and an array of ``ChangelogSection`` values (e.g., "Added", "Fixed"). Each section contains ``ChangelogEntry`` values with an optional scope, message, and breaking-change flag.

```
ChangelogRelease
├── version: "0.4.0"
├── date: "2025-01-15"
└── sections:
    ├── ChangelogSection(title: "Added")
    │   ├── ChangelogEntry(scope: "dashboard", message: "New team view...")
    │   └── ChangelogEntry(scope: nil, message: "Real-time status polling")
    └── ChangelogSection(title: "Fixed")
        └── ChangelogEntry(scope: "auth", message: "Token refresh loop...", isBreaking: false)
```

### Breaking Changes

Entries prefixed with `**breaking**`, `**BREAKING**`, or `[**breaking**]` are flagged with `isBreaking: true` and rendered in ``Catalyst/red``.

## Displaying the Changelog

``ChangelogView`` renders the parsed releases as expandable cards. The most recent release is expanded by default.

```swift
struct AboutView: View {
    let releases = ChangelogParser.fromBundle()

    var body: some View {
        ChangelogView(releases: releases)
    }
}
```

### Visual Design

- Each release is a glass card with a clickable header showing version, date, and change count
- Section titles are color-coded: green for Added, red for Fixed, yellow for Performance, blue for Refactored, magenta for Breaking/Removed, pink for Docs
- Breaking entries are highlighted in red with a colored bullet
- Scoped entries show the scope in bold before the message
- Empty state shows a placeholder when no releases are available
