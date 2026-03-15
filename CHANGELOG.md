# Changelog

All notable changes to P-Arr will be documented in this file.

## [0.2.0] - 2026-03-14

### Features

- Rename from PR Widget to P-Arr (new bundle ID, product name, keychain service)
- Add reusable persistence layer in catalyst-swift (Persisted, PersistedCodable, PersistedSecret)
- Add author filter with include/exclude chips (same tri-state pattern as labels)
- Make settings window resizable with persisted dimensions
- Add sidebar-style tab navigation in settings
- Persist label and author filter selections across launches

### Changed

- Refactor all stores to use type-safe persistence descriptors (removes ~100 lines of boilerplate)
- Migrate UserDefaults keys from PRWidget.* to PArr.* prefix
- Migrate Keychain service from com.catalyst.prwidget to com.catalyst.p-arr

## [0.1.0] - 2026-03-12

### Features

- Floating NSPanel dashboard (stays visible across Spaces)
- GitHub GraphQL API v4 integration for PR fetching
- Multi-account support with macOS Keychain token storage
- PR categorization by urgency score (age + review state + CI + conflicts + size)
- Label filter with include/exclude chips
- Pin/unpin PRs to top section
- Collapsible repo groups with drag-to-reorder
- Full-text search across PR title, repo, branch, author
- PR detail view with activity feed and timeline
- AI synopsis engine (OpenAI + Ollama) with customizable prompts
- Global hotkey (Cmd+Shift+Option+P) with configurable recording
- Mention tracking with unread badge on menu bar icon
- Quick actions: merge, approve, request changes
- In-app changelog viewer
- Catalyst cybersynthpunk dark theme
