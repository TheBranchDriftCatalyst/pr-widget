# Updates

Homebrew cask self-update integration for Catalyst macOS apps distributed via a tap.

## Overview

The Updates module provides ``BrewSelfUpdater``, an observable object that checks for new versions of your app through Homebrew, and ``BrewUpdateView``, a ready-made settings panel for displaying version status and triggering updates.

## How It Works

1. ``BrewSelfUpdater`` runs `brew info --cask <name> --json=v2` to fetch the latest version from your Homebrew tap
2. It compares the tap version against `Bundle.main.appVersion`
3. If an update is available, the user can trigger `performUpdate()`, which:
   - Writes a temporary shell script to `/tmp/`
   - Opens Terminal to run the script
   - Quits the current app
   - The script waits for the app to exit, runs `brew upgrade --cask`, then reopens the app

## Setup

Initialize the updater with your cask name and app name:

```swift
@MainActor
class AppState {
    let updater = BrewSelfUpdater(caskName: "p-arr", appName: "P-Arr")
}
```

Check for updates on launch or on demand:

```swift
Task {
    await updater.checkForUpdate()
}
```

## Settings View

``BrewUpdateView`` provides a complete settings panel:

```swift
struct UpdateSettingsView: View {
    let updater: BrewSelfUpdater

    var body: some View {
        BrewUpdateView(updater: updater)
    }
}
```

The view displays:
- Current installed version
- Update status (checking, up-to-date, update available, error)
- "Check for Update" / "Check Again" button
- "Update to vX.Y.Z" button when an update is available
- Homebrew command hint at the bottom

## Error Handling

``BrewUpdateError`` covers three failure cases:

| Case | Meaning |
|------|---------|
| `.brewNotFound` | Homebrew is not installed at the expected paths |
| `.caskNotFound(name)` | The specified cask is not in any installed tap |
| `.parseError` | The JSON output from `brew info` could not be parsed |

All errors are `LocalizedError` with user-friendly messages.

## Requirements

- The app must be distributed via a Homebrew cask in a tap
- Homebrew must be installed at `/opt/homebrew/bin/brew` (Apple Silicon) or `/usr/local/bin/brew` (Intel)
- The app's `CFBundleShortVersionString` must match the cask versioning scheme
