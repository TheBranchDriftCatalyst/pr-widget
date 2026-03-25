# PR Widget

Native macOS floating dashboard for GitHub PR management. Menu bar app (LSUIElement) with floating NSPanel.

## Quick Start

```bash
task setup     # Install deps (fswatch, xcbeautify)
task dev       # Live-reload development
task build     # Build only
task run       # Build + bundle + launch
task test      # Run unit tests
task open      # Open in Xcode (generates xcodeproj via xcodegen)
```

## Architecture

- **Swift 6 + SwiftUI** on macOS 14+
- **SPM** for dependency management and building
- **XcodeGen** for generating .xcodeproj (IDE use only)
- **NSPanel** floating window (stays visible across Spaces)
- **GitHub GraphQL API v4** for all data fetching
- **macOS Keychain** for secure token storage
- **Carbon hotkey API** for global keyboard shortcut (Cmd+Shift+Option+P)

## Project Structure

```
PRWidget/
├── App/           # Entry point + AppDelegate (menu bar, lifecycle)
├── Window/        # FloatingPanel (NSPanel) + WindowManager
├── Models/        # GitHubAccount, PullRequest, DashboardState
├── GraphQL/       # Queries, Mutations, ResponseTypes (Decodable)
├── Networking/    # GitHubGraphQLClient, APIError
├── Auth/          # KeychainManager, AccountManager
├── Services/      # HotkeyManager, PollingScheduler (Phase 2)
├── Store/         # DashboardStore (ObservableObject), ActionHandler
├── Views/         # SwiftUI views (Dashboard, Team, Actions, Settings, Components)
├── Extensions/    # JSONDecoder+GitHub, Color+Hex
└── Resources/     # Assets.xcassets, Info.plist, entitlements
```

## Build System

- Primary build: `swift build` (SPM)
- App bundling: `scripts/bundle.sh` (assembles .app from build output)
- Dev mode: `task dev` (fswatch → rebuild → relaunch on file changes)
- Xcode project: `task generate` (xcodegen from project.yml)

## Release Workflow

```bash
task ship -- patch|minor|major   # Full release: bump → changelog → package → cask → tag → publish
task release -- patch            # Cut release only (no GitHub release)
task publish                     # Create GitHub release from existing tag + package
```

**Release flow (`task ship`):**
1. Bump version (VERSION + project.yml)
2. Generate changelog via `git-cliff --tag vX.Y.Z` (conventional commits)
3. Package (build release → bundle .app → zip)
4. Update Homebrew cask formula (SHA256 from zip)
5. Commit all + tag + push
6. Create GitHub release + upload zip

**Changelog rules (`cliff.toml`):**
- Generated from conventional commit prefixes (`feat:`, `fix:`, `refactor:`, etc.)
- `chore(release):` and `chore: update catalyst-cask` commits are skipped (infrastructure noise)
- Changelog is generated before packaging so the app bundle always has the current version's entry

**Homebrew distribution:**
- Cask lives in `catalyst-cask/` submodule (TheBranchDriftCatalyst/homebrew-catalyst tap)
- `brew install TheBranchDriftCatalyst/catalyst/p-arr`

## Key Patterns

- `@MainActor` on all UI-facing classes (Swift 6 strict concurrency)
- GraphQL responses decoded to flat `Decodable` structs, then mapped to domain models via `PRNode.toPullRequest()`
- PRs categorized by computed properties on `DashboardState` (needsAction, readyToShip, waitingOnOthers)
- Urgency score computed from age + review state + CI status + conflicts + size
- Menu bar badge shows sum of: reviews you owe + your PRs awaiting review, scoped to active filter set
- CatalystSwift lib (`catalyst-lib/`) provides reusable components: theme, persistence, changelog viewer, brew updater, log viewer, icon theming
