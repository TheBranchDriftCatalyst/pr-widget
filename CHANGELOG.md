# Changelog

All notable changes to P-Arr will be documented in this file.

## [1.0.0] - 2026-04-09

### Features

- Native macOS menu bar app (LSUIElement) with floating NSPanel dashboard
- Rename to P-Arr with DRY persistence layer
- GitHub GraphQL v4 API with multi-account support
- Smart PR triage: Needs Action / Ready to Ship / Waiting on Others categories
- Urgency scoring computed from age + review state + CI status + conflicts + size
- Badge shows owed reviews + pending PRs from current filter set
- Show your review state as a pill badge in PR rows
- Inline diff viewer with review thread comments and reply support
- Quick actions: approve, request changes, merge from dashboard with merge confirmation
- Global hotkey (Cmd+Shift+Option+P) via Carbon Events API
- macOS Keychain token storage per account
- Replace menu bar icon with new full-color p-arr icon
- Icon theming system with customizable menu bar icon variants
- AI-powered PR synopses (Ollama + OpenAI providers)
- Label and author filtering with include/exclude support
- PR pinning, repo grouping, drag-to-reorder repos
- @mention tracking with unread badges
- Shared homebrew tap, diff viewer, polling, XCUITest infrastructure
- Homebrew Cask distribution (`brew install TheBranchDriftCatalyst/catalyst/p-arr`)
- Homebrew self-update via Settings > Updates tab
- Add Logs tab to settings with reusable CatalystSwift LogViewer
- Add diagnostics settings tab with live resource monitor and CPU sampling
- Add UI text scale setting with CatalystSwift UIScale module
- Add update dot indicator on settings gear + design audit report
- Add design system tokens to CatalystTheme
- **uiscale**: Migrate all raw .font(.system(size:)) to .scaledFont()
- **a11y**: Add accessibility support for reduce motion, transparency, color, and VoiceOver
- Unify filter system, fix click behavior, add shortcuts, standardize tooltips
- Icon theming, brew updates, and catalyst-lib improvements
- Icon theming system, build pipeline, and DocC documentation
- Branded release output with clean step indicators
- Add fire-and-forget 'task ship' command and update release docs

### Performance

- Resolve 48s main thread hang from synchronous OSLog XPC — async LogStore off main thread
- LRU cache for file diffs (capped at 15 PRs) and PR details (capped at 10)
- Disk-backed ETag cache — response data in ~/Library/Caches/, only etag strings in RAM
- MentionTracker seenMentionIDs pruning (capped at 500)
- LogStore entry cap (500 entries, 10-minute window)
- Dead code removal, architecture fixes, and caching improvements

### Bug Fixes

- Use updated PR with detail for diff file loading
- Repair MentionTracker — 3 defects (P0-3)
- Comment data loss, multi-monitor positioning, brand naming
- Address QA review findings on design tokens
- Address remaining QA review findings
- Resolve 5 concurrency issues for Swift 6 strict concurrency
- Use GitHubGraphQLClient.shared in ActionHandler
- **networking**: Harden API layer — GHE URLs, decode safety, retry, cache eviction
- Store/state layer — multi-account, caching, error handling, pin ownership
- Resolve infinite layout loop when clicking SearchBar TextField
- Use absolute brew path and bundle path in update script
- Run brew update before checking for new cask versions
- Copy resource bundle to app root for SPM compatibility
- Suppress swift build noise in package script
- Pass --tag to git-cliff so releases aren't labeled Unreleased
- Skip catalyst-cask update commits from changelog
- Reorder ship task so cask update is included before the tag
- Fix release ordering so cask update appears in correct version
- Single changelog generation before packaging
- Generate changelog before packaging so app bundle has current version entry

### Refactor

- Migrate all raw fonts to scaledFont and hardcoded colors to tokens
- Deduplicate views and extract shared components
- Extract shared components (ToggleChip, SectionHeader, EmptyState, FlowLayout, relativeTime)
- Networking layer — GHE URLs, decode safety, retry, ETag cache eviction
- Store/state layer — multi-account, caching, error handling, pin ownership
- View deduplication — CollapsibleFilterSection, CountBadge, NeonDot, DashboardView decomposition
- Design audit implementation — 8 workstreams, all QA reviewed

### Documentation

- Add release workflow and key patterns to project docs
- Add release process documentation
- Add actor-critic agent loop contracts
- Add LICENSE, harden .gitignore, add agent docs for public release

### Infrastructure

- Swift 6 strict concurrency throughout
- SPM build + XcodeGen for IDE
- `task ship` fire-and-forget release pipeline (version bump, git-cliff changelog, release build, .app bundle, zip, Homebrew cask update, git tag, GitHub release)
- Conventional commits with git-cliff changelog generation
- Add git push to release task for tags and commits
- Update homebrew-catalyst tap for distribution
