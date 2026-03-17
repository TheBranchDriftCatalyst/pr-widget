# Changelog

All notable changes to PR Widget will be documented in this file.

## [Unreleased]

### Bug Fixes

- Suppress swift build noise in package script

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.7

## [0.6.7] - 2026-03-17

### Features

- Branded release output with clean step indicators

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.6

## [0.6.6] - 2026-03-17

### Features

- Add fire-and-forget 'task ship' command and update release docs

### Miscellaneous

- Add git push to release task for tags and commits
- Update catalyst-cask to p-arr v0.6.5

## [0.6.5] - 2026-03-17

### Bug Fixes

- Resolve infinite layout loop when clicking SearchBar TextField

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.4

## [0.6.4] - 2026-03-17

### Bug Fixes

- Use absolute brew path and bundle path in update script

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.3

## [0.6.3] - 2026-03-17

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.2

## [0.6.2] - 2026-03-17

### Bug Fixes

- Run brew update before checking for new cask versions

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.1

## [0.6.1] - 2026-03-17

### Miscellaneous

- Update catalyst-cask to p-arr v0.6.0

## [0.6.0] - 2026-03-17

### Bug Fixes

- Resolve 5 concurrency issues for Swift 6 strict concurrency
- Dead code removal, architecture fixes, and caching improvements
- Use GitHubGraphQLClient.shared in ActionHandler
- **networking**: Harden API layer — GHE URLs, decode safety, retry, cache eviction
- Store/state layer — multi-account, caching, error handling, pin ownership

### Features

- Icon theming, brew updates, and catalyst-lib improvements

### Miscellaneous

- Update catalyst-cask to p-arr v0.5.0

### Refactor

- Migrate all raw fonts to scaledFont and hardcoded colors to tokens
- Deduplicate views and extract shared components

### Merge

- Networking layer — GHE URLs, decode safety, retry, ETag cache eviction
- Store/state layer — multi-account, caching, error handling, pin ownership
- View deduplication — CollapsibleFilterSection, CountBadge, NeonDot, DashboardView decomposition

## [0.5.0] - 2026-03-15

### Features

- Icon theming system, build pipeline, and DocC documentation

### Miscellaneous

- Update homebrew-catalyst to p-arr v0.4.0

## [0.4.0] - 2026-03-15

### Bug Fixes

- Repair MentionTracker — 3 defects (P0-3)
- Comment data loss, multi-monitor positioning, brand naming
- Address QA review findings on design tokens
- Address remaining QA review findings

### Features

- Add update dot indicator on settings gear + design audit report
- Wire QuickActionsView into PRDetailView and add merge confirmation
- Add design system tokens to CatalystTheme
- **uiscale**: Migrate all raw .font(.system(size:)) to .scaledFont()
- **a11y**: Add accessibility support for reduce motion, transparency, color, and VoiceOver
- Unify filter system, fix click behavior, add shortcuts, standardize tooltips

### Miscellaneous

- Update homebrew-catalyst to p-arr v0.3.3

### Refactor

- Extract shared components (ToggleChip, SectionHeader, EmptyState, FlowLayout, relativeTime)

### Merge

- Design audit implementation — 8 workstreams, all QA reviewed

## [0.3.3] - 2026-03-15

### Documentation

- Add release process documentation

### Features

- Add UI text scale setting with CatalystSwift UIScale module

### Miscellaneous

- Update homebrew-catalyst to p-arr v0.3.2

## [0.3.2] - 2026-03-15

### Features

- Add Homebrew self-update via Settings > Updates tab

### Miscellaneous

- Update homebrew-catalyst to p-arr v0.3.1

## [0.3.1] - 2026-03-15

### Documentation

- Add actor-critic agent loop contracts

### Miscellaneous

- Update homebrew-catalyst to p-arr v0.3.0
- Add LICENSE, harden .gitignore, add agent docs for public release

## [0.3.0] - 2026-03-15

### Features

- Add shared homebrew tap, diff viewer, polling, XCUITest infrastructure

## [0.2.0] - 2026-03-14

### Features

- Rename to P-Arr with DRY persistence layer


