# P-Arr

Native macOS floating dashboard for GitHub PR management. Menu bar app with urgency scoring, quick actions, and diff viewing.

![macOS](https://img.shields.io/badge/macOS-15%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift)
![License](https://img.shields.io/badge/license-MIT-blue)

## Install

```bash
brew tap TheBranchDriftCatalyst/catalyst
brew install --cask p-arr
```

Or build from source — see [Development](#development).

## Features

- **Floating panel** — NSPanel stays visible across all Spaces and desktops
- **Urgency scoring** — PRs ranked by age, review state, CI status, conflicts, and size
- **Quick actions** — Approve, request changes, or merge directly from the widget
- **Diff viewer** — Inline and split diff views with syntax context
- **Global hotkey** — `Cmd+Shift+Option+P` to toggle the panel
- **Auto-refresh** — Configurable polling interval
- **GitHub GraphQL v4** — Efficient batched queries
- **Keychain storage** — Tokens never leave macOS Keychain

## Architecture

```
PRWidget/
├── App/           # AppDelegate, menu bar lifecycle
├── Window/        # FloatingPanel (NSPanel), WindowManager
├── Models/        # GitHubAccount, PullRequest, DashboardState, PRFileDiff
├── GraphQL/       # Queries, Mutations, ResponseTypes
├── Networking/    # GitHubGraphQLClient, RESTFileDiff, APIError
├── Auth/          # KeychainManager, AccountManager
├── Services/      # HotkeyManager, PollingScheduler, DiffParser
├── Store/         # DashboardStore, ActionHandler
├── Views/         # SwiftUI (Dashboard, Detail, Diff, Settings, Components)
├── Extensions/    # JSONDecoder+GitHub, Color+Hex
└── Resources/     # Assets.xcassets, Info.plist, entitlements
```

**Key patterns:**
- Swift 6 strict concurrency (`@MainActor` on all UI-facing classes)
- GraphQL responses → flat `Decodable` structs → domain models via `PRNode.toPullRequest()`
- PR categorization via computed properties: `needsAction`, `readyToShip`, `waitingOnOthers`

## Development

### Prerequisites

- macOS 15+ (Sequoia)
- Xcode Command Line Tools or full Xcode
- [go-task](https://taskfile.dev/) (`brew install go-task`)

### Quick Start

```bash
task setup       # Install deps (fswatch, xcbeautify, lefthook, git-cliff)
task dev         # Live-reload development (fswatch → rebuild → relaunch)
```

### All Tasks

| Task | Description |
|------|-------------|
| `task build` | Debug build (SPM) |
| `task build:release` | Release build (optimized) |
| `task bundle` | Assemble .app bundle |
| `task run` | Build + bundle + launch |
| `task dev` | Live-reload development |
| `task test` | Unit tests |
| `task test:ui` | XCUITest UI tests |
| `task open` | Open in Xcode (generates xcodeproj) |
| `task clean` | Clean build artifacts |

### Release Workflow

```bash
task release -- minor     # Bump version, changelog, commit, tag
task package              # Release build → .zip
task publish              # GitHub release + update Homebrew tap
```

See [Taskfile.yml](Taskfile.yml) for all available tasks.

## Documentation

| Document | Audience | Description |
|----------|----------|-------------|
| [CLAUDE.md](CLAUDE.md) | AI agents | Project context for Claude Code sessions |
| [AGENTS.md](AGENTS.md) | AI agents | Agent workflow, contracts, and session protocols |
| [CHANGELOG.md](CHANGELOG.md) | Everyone | Release history |
| [docs/release.md](docs/release.md) | Developers | Full release process and troubleshooting |
| [PRWidgetUITests/TEST_PLAN.md](PRWidgetUITests/TEST_PLAN.md) | Developers | XCUITest coverage plan |

Shared agent contracts and AI development framework docs live at the workspace level: [`catalyst-devspace/docs/`](../../docs/).

## License

[MIT](LICENSE)
