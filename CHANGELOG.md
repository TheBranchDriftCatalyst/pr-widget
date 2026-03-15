# Changelog

All notable changes to PR Widget will be documented in this file.

## [Unreleased]

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


