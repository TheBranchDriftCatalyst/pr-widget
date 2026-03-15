# Release Process

P-Arr is distributed as a macOS app via Homebrew cask. This document covers the full release lifecycle.

## Prerequisites

- [Homebrew](https://brew.sh) installed
- [GitHub CLI](https://cli.github.com) (`gh`) installed and authenticated
- [go-task](https://taskfile.dev) installed
- [git-cliff](https://git-cliff.org) installed (for changelog generation)
- Push access to `TheBranchDriftCatalyst/pr-widget` and `TheBranchDriftCatalyst/homebrew-catalyst`
- The `homebrew-catalyst` submodule initialized (`task cask:setup`)

## Quick Reference

```bash
# Patch release (bugfixes)
task release:patch

# Minor release (new features)
task release:minor

# Major release (breaking changes)
task release:major

# Then package, publish, and push
task publish
git push --follow-tags
```

## Step-by-Step

### 1. Commit your code changes

Ensure all feature/fix commits are on `main` with conventional commit messages:

```bash
git add <files>
git commit -m "feat: add self-update via Settings"
```

Conventional commit prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `perf:`

### 2. Cut the release

```bash
task release:patch    # or release:minor / release:major
```

This does three things automatically:
1. **Bumps VERSION** — increments the version in `VERSION` and `project.yml` (`MARKETING_VERSION`)
2. **Generates CHANGELOG.md** — runs `git-cliff` to produce a changelog from conventional commits
3. **Commits and tags** — creates a `chore(release): vX.Y.Z` commit and a `vX.Y.Z` git tag

### 3. Build and package

```bash
task package
```

This runs:
1. `swift build -c release` — optimized release build
2. `scripts/bundle.sh` — assembles the `.app` bundle with Info.plist, entitlements, and assets
3. Creates `P-Arr-X.Y.Z.zip` in `.build/`

### 4. Publish to GitHub + Homebrew

```bash
task publish
```

This runs:
1. `task package` (if not already done)
2. Creates a GitHub release via `gh release create` with the zip attached
3. Updates `homebrew-catalyst/Casks/p-arr.rb` with the new version and SHA256
4. Commits and pushes the updated cask to the `homebrew-catalyst` submodule
5. Updates the submodule ref in the parent repo

### 5. Push everything

```bash
git push --follow-tags
```

Pushes the release commit, tag, and submodule ref update to the remote.

## Version Files

| File | Field | Updated by |
|------|-------|------------|
| `VERSION` | Plain text version | `task version:bump` |
| `project.yml` | `MARKETING_VERSION` | `task version:bump` |
| `homebrew-catalyst/Casks/p-arr.rb` | `version` + `sha256` | `task cask:update` (called by `publish`) |

The `VERSION` file is the single source of truth. All other version references are derived from it.

## Individual Task Reference

| Task | Description |
|------|-------------|
| `task version:bump -- patch\|minor\|major` | Bump version in VERSION + project.yml |
| `task changelog` | Regenerate CHANGELOG.md via git-cliff |
| `task release -- patch\|minor\|major` | Bump + changelog + commit + tag |
| `task release:patch` | Shorthand for `task release -- patch` |
| `task release:minor` | Shorthand for `task release -- minor` |
| `task release:major` | Shorthand for `task release -- major` |
| `task package` | Build release + bundle .app + create .zip |
| `task publish` | GitHub release + Homebrew cask update |
| `task cask:update` | Update cask formula with current version/SHA |
| `task cask:setup` | Initialize the homebrew-catalyst submodule |

## Homebrew Tap

P-Arr is distributed via a custom Homebrew tap:

```bash
brew tap TheBranchDriftCatalyst/catalyst
brew install --cask p-arr
```

The tap lives in the `homebrew-catalyst/` submodule (pointing to `TheBranchDriftCatalyst/homebrew-catalyst`). The `task publish` command handles updating it automatically.

Users update with:

```bash
brew upgrade --cask p-arr
```

## Troubleshooting

**`gh` not authenticated:**
```bash
gh auth login
```

**Submodule not initialized:**
```bash
task cask:setup
```

**Package step fails with signing error:**
The app uses ad-hoc signing (`CODE_SIGN_IDENTITY: "-"`). No Apple Developer account needed.

**SHA256 mismatch after publish:**
Re-run `task cask:update` — it computes the SHA from the local zip. Make sure you haven't rebuilt after uploading.
