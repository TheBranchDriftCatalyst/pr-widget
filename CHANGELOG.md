# Changelog

All notable changes to PR Widget will be documented in this file.

## [1.1.1] - 2026-04-23

### Bug Fixes

- Improve PR row layout with icon stack, scrollable labels, and wider window support

## [1.1.0] - 2026-04-23

### Features

- Match PR rows to GitHub layout with comment count, task progress, and refresh settings

## [0.7.5] - 2026-04-09

### Features

- Add diagnostics settings tab with live resource monitor and CPU sampling

## [0.7.4] - 2026-04-09

### Bug Fixes

- Resolve 48s main thread hang from synchronous OSLog XPC + reduce memory footprint

## [0.7.3] - 2026-03-26

### Documentation

- Add release workflow and key patterns to project docs

### Features

- Replace menu bar icon with new full-color p-arr icon

## [0.7.2] - 2026-03-25

### Bug Fixes

- Single changelog generation before packaging

## [0.7.1] - 2026-03-25

### Bug Fixes

- Generate changelog before packaging so app bundle has current version entry

## [0.7.0] - 2026-03-25

### Bug Fixes

- Use updated PR with detail for diff file loading

### Features

- Badge shows owed reviews + pending PRs from current filter set
- Show your review state as a pill badge in PR rows
- Add Logs tab to settings with reusable CatalystSwift LogViewer

## [0.6.12] - 2026-03-24

### Refactor

- Fix release ordering so cask update appears in correct version

## [0.6.11] - 2026-03-24

### Bug Fixes

- Skip catalyst-cask update commits from changelog
- Reorder ship task so cask update is included before the tag

## [0.6.10] - 2026-03-24

### Bug Fixes

- Pass --tag to git-cliff so releases aren't labeled Unreleased

## [0.6.9] - 2026-03-24

### Bug Fixes

- Copy resource bundle to app root for SPM compatibility

## [0.6.8] - 2026-03-17

### Bug Fixes

- Suppress swift build noise in package script

## [0.6.7] - 2026-03-17

### Features

- Branded release output with clean step indicators

## [0.6.6] - 2026-03-17

### Features

- Add fire-and-forget 'task ship' command and update release docs

### Miscellaneous

- Add git push to release task for tags and commits

## [0.6.5] - 2026-03-17

### Bug Fixes

- Resolve infinite layout loop when clicking SearchBar TextField

## [0.6.4] - 2026-03-17

### Bug Fixes

- Use absolute brew path and bundle path in update script

## [0.6.2] - 2026-03-17

### Bug Fixes

- Run brew update before checking for new cask versions

## [0.6.0] - 2026-03-17

### Bug Fixes

- Resolve 5 concurrency issues for Swift 6 strict concurrency
- Dead code removal, architecture fixes, and caching improvements
- Use GitHubGraphQLClient.shared in ActionHandler
- **networking**: Harden API layer — GHE URLs, decode safety, retry, cache eviction
- Store/state layer — multi-account, caching, error handling, pin ownership

### Features

- Icon theming, brew updates, and catalyst-lib improvements

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


