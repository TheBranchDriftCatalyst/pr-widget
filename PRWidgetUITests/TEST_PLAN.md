# P-Arr XCUITest Coverage Plan

Comprehensive UI test plan for the P-Arr macOS floating PR dashboard.

---

## A. Screen/Component Inventory

### 1. Dashboard Screen (`DashboardView`)

| View | Displays | Interactions |
|------|----------|-------------|
| `DashboardHeaderBar` | App title "PR WIDGET", version, summary count badges (blocked, owned, ready-for-QA), last-refreshed timestamp, polling interval | Refresh button, Pin/Unpin toggle, Settings button |
| `FilterBar` | Horizontal scroll of filter chips: All, My PRs, Review Requested, Mentioned, Blocked by Me | Tap chip to activate filter |
| `SearchBar` | Search text field with magnifying glass icon, clear button | Type to search, tap X to clear |
| `LabelFilterView` | Expandable "LABELS" header with active filter count, flow-layout label chips | Expand/collapse, tap chip to include, Cmd+click to exclude, CLEAR button |
| `AuthorFilterView` | Expandable "AUTHORS" header with active filter count, flow-layout author chips | Expand/collapse, tap chip to include, Cmd+click to exclude, CLEAR button |
| `PinnedSection` | Pinned PR rows with pin icon and yellow accent | Tap PR to navigate to detail |
| `RepoGroupSection` | Collapsible repo header with chevron, repo name, PR count badge; contains PR rows | Click header to collapse/expand, Cmd+click to toggle all, drag to reorder |
| `PRRowContent` | PR title, repo#number, draft icon, pin icon, urgency badge, status badge, review avatars, conflicts indicator, +/- line counts, label pills | Tap to navigate to detail, right-click context menu (Pin, Open in Browser, Copy URL, Copy Branch, Labels) |
| `noAccountView` | "NO ACCOUNTS" message with person.badge.key icon, "Open Settings" button | Tap "Open Settings" |
| `emptyStateView` | "INBOX ZERO" message with checkmark.circle icon | None |
| `noMatchView` | "NO MATCHES" with magnifying glass icon | None |
| `ErrorBannerView` | Error message with pulsing warning icon | None (display-only) |

### 2. PR Detail Screen (`PRDetailView`)

| View | Displays | Interactions |
|------|----------|-------------|
| Back bar | "BACK" button, repo name, PR #number | Tap BACK to dismiss |
| `detailHeader` | State badge (OPEN/MERGED/CLOSED), repo, PR title, head->base branches, author, age, +/- lines, changed files count, "Open in GitHub" button | Tap "Open in GitHub" |
| `SynopsisCard` | "AI SYNOPSIS" header, provider badge, summary text, action items, urgency reason; loading shimmer; "No synopsis available" fallback | None (display-only) |
| `checksSection` | "CHECKS" header, list of check runs with status icons (success/failure/pending/error/unknown), names, conclusions | None (display-only) |
| `ActivityFeed` | "ACTIVITY" header, chronological list of comments and timeline events | None (display-only) |
| `loadingView` | Spinner + "LOADING DETAILS..." text with shimmer | None |
| `errorView` | Warning icon + "Failed to load details" | None |

### 3. Diff Panel (`DiffPanelView`)

| View | Displays | Interactions |
|------|----------|-------------|
| Header bar | PR #number, title, repo name, open-in-browser arrow | Tap arrow to open in browser |
| `FileListSidebar` | List of changed files with change-type icons (added/removed/modified/renamed/copied), filename, full path, +/- counts, comment thread count | Tap file to select |
| `DiffContentView` | File header with path and +/- counts, hunk headers, diff lines (additions green, deletions red, context gray) with line numbers | Text selection on diff lines |
| `InlineCommentThread` | Expandable thread header with comment count, RESOLVED/OUTDATED badges, comment rows with author/time/body | Expand/collapse thread |
| `CommentComposer` | TextEditor for reply, Submit button with loading state | Type reply, tap Reply button |
| Loading/Error/Empty states | "LOADING DIFFS...", error message with Retry button, "NO FILE CHANGES", "SELECT A FILE" | Retry button on error |
| `noPatchView` | "Binary file or diff too large" message | None |

### 4. Quick Actions (`QuickActionsView`)

| View | Displays | Interactions |
|------|----------|-------------|
| Approve button | "Approve" with checkmark icon | Tap to approve PR |
| Merge button | "Merge" with merge icon | Tap to show merge options popover |
| Request Changes button | "Request Changes" with exclamation icon | Tap to show request changes popover |

### 5. Merge Options (`MergeOptionsView`)

| View | Displays | Interactions |
|------|----------|-------------|
| "MERGE METHOD" header | Title in magenta | None |
| Method rows | Icon + method name (Squash, Merge, Rebase) with hover highlight | Tap to select merge method |

### 6. Request Changes (`RequestChangesPopover`)

| View | Displays | Interactions |
|------|----------|-------------|
| "REQUEST CHANGES" header | Title in warning color | None |
| Text field | Multi-line text field for change description | Type comment |
| Submit button | "Submit" button, disabled when empty | Tap to submit |

### 7. Settings Window (`SettingsView`)

| Tab | View | Displays | Interactions |
|-----|------|----------|-------------|
| Accounts | `AccountsSettingsView` | List of accounts (avatar, username, host), "Add Account..." button | Remove account (trash icon), Add Account sheet |
| Accounts | `AccountSetupView` (sheet) | Host type picker (Cloud/Enterprise), Enterprise host field, PAT secure field, error message, verifying spinner | Select host type, enter token, Cancel, Add Account |
| AI | `AISettingsView` | Provider fallback chain (Ollama -> OpenAI -> Algorithmic), Ollama config (toggle, base URL, model picker/field, refresh), OpenAI config (toggle, API key, model) | Toggle providers, edit URLs/keys/models, refresh Ollama models |
| Prompt | `PromptSettingsView` | Prompt template editor, response format editor, available variables reference table | Edit templates, Reset button |
| General | `GeneralSettingsView` | Keyboard shortcut recorder, About section (app name, version) | Record new shortcut, Reset shortcut |
| Changelog | `ChangelogView` | Release notes | Scrollable display |
| Help | `HelpSettingsView` | Help tips organized by category | Scrollable display |

### 8. Team Views (Phase 3 Placeholder)

| View | Displays | Interactions |
|------|----------|-------------|
| `TeamDashboardView` | "TEAM DASHBOARD" with "Coming in Phase 3" | None |
| `AgingBoardView` | "PR AGING BOARD", list of PRs with age-colored dots and age text | None (display-only) |

### 9. Shared Components

| Component | Displays | Used In |
|-----------|----------|---------|
| `UrgencyBadge` | Age text with color-coded background (muted < 2, yellow < 4, warning < 6, red >= 6) | PRRowContent, PRRowView |
| `StatusBadge` | CI status icon + text (Passing/Failing/Error/Pending/No checks) | PRRowContent, PRRowView |
| `ReviewAvatars` | Overlapping reviewer avatars with state indicators (approved/changes/commented/dismissed/pending) + pending review request avatars | PRRowContent, PRRowView |
| `LabelPill` | Label name with hex-colored background | PRRowContent, PRRowView |
| `LabelContextMenu` | Context menu with label add/remove/re-apply actions | PRRowContent, PRRowView |
| `PRRowView` | Full PR row (legacy standalone version, opens in browser) | PRListView |
| `PRListView` | Section with header and list of PRRowViews | (may be unused in current dashboard) |

---

## B. User Flows

### Flow 1: App Launch -> Dashboard
1. App starts as menu bar item (LSUIElement)
2. Click menu bar icon -> floating panel appears below status item
3. If no accounts: "NO ACCOUNTS" view with "Open Settings" button
4. If accounts exist: dashboard refreshes, shows PR list grouped by repo
5. Loading state shown during refresh

### Flow 2: PR List Interaction
1. PRs displayed in repo groups, sorted by urgency score
2. Color-coded accent stripes: green (ready to ship), red (needs action), blue (waiting)
3. Filter bar: tap filter chip to switch between All/My PRs/Review Requested/Mentioned/Blocked by Me
4. Search bar: type to filter by title/repo/branch/author
5. Label filter: expand, click to include (yellow), Cmd+click to exclude (red strikethrough)
6. Author filter: same include/exclude mechanics
7. Repo groups: click header to collapse/expand, Cmd+click to toggle all
8. Pin PR: right-click -> Pin, appears in dedicated "Pinned" section at top
9. Context menu: Open in Browser, Copy URL, Copy Branch, Labels submenu

### Flow 3: PR Detail View
1. Click any PR row -> NavigationLink pushes PRDetailView
2. Back bar with "BACK" button and PR identifier
3. Header: state badge, title, branches, author, age, line counts
4. "Open in GitHub" button
5. AI Synopsis card (loading shimmer -> summary/action items/urgency)
6. Checks section (if any CI checks exist)
7. Activity feed (comments + timeline events, chronological)

### Flow 4: Diff Panel
1. Clicking a PR row also triggers onOpenDiffPanel -> separate NSWindow opens
2. File list sidebar on left, diff content on right
3. Select file to view its patch
4. Inline comment threads appear at relevant diff lines
5. Expand/collapse threads, reply to threads via CommentComposer

### Flow 5: Actions (Approve/Merge/Request Changes)
1. QuickActionsView shown in detail context
2. Approve: single tap action
3. Merge: opens MergeOptionsView popover (Squash/Merge/Rebase)
4. Request Changes: opens RequestChangesPopover with text field

### Flow 6: Settings / Account Management
1. Click gear icon or right-click menu bar -> "Settings..."
2. Settings window opens with tab bar (Accounts, AI, Prompt, General, Changelog, Help)
3. Accounts tab: view existing accounts, remove, add new
4. Add Account: select Cloud/Enterprise, enter PAT, verify, add
5. AI tab: toggle Ollama/OpenAI providers, configure endpoints/keys/models
6. Prompt tab: edit synopsis prompt template and response format
7. General tab: record custom keyboard shortcut, view About info

### Flow 7: Keyboard Shortcut
1. Default: Cmd+Shift+Option+P toggles panel visibility
2. Customizable via General settings
3. Panel appears/disappears with fade animation

### Flow 8: Window Pin/Unpin
1. Pin button in header bar toggles window pinning
2. Pinned: window stays visible when losing focus (level = statusBar)
3. Unpinned: window hides when it loses key focus

### Flow 9: Escape to Dismiss
1. Press Escape while panel is visible -> panel hides
2. FloatingPanel.cancelOperation triggers hide

### Flow 10: Auto-Refresh / Polling
1. PollingScheduler auto-refreshes at configurable interval
2. Header shows polling interval and green dot indicator when active
3. Manual refresh via refresh button

---

## C. State Coverage

### Loading States
- `DashboardView`: `store.state.isLoading` -> ProgressView in refresh button
- `PRDetailView`: `isLoadingDetail` -> spinner + "LOADING DETAILS..." + shimmer
- `SynopsisCard`: `isLoading` with no synopsis -> spinner + "Generating synopsis..."
- `DiffPanelView`: `isLoading` -> spinner + "LOADING DIFFS..."
- `AccountSetupView`: `isVerifying` -> spinner + "Verifying token..."
- `CommentComposer`: `isSubmitting` -> spinner in Reply button

### Empty States
- No accounts: `!accountManager.hasAccounts` -> noAccountView ("NO ACCOUNTS")
- No PRs: `store.state.isEmpty && !store.state.isLoading` -> emptyStateView ("INBOX ZERO")
- No filter matches: `groups.isEmpty && pinned.isEmpty` -> noMatchView ("NO MATCHES")
- No activity: `activities.isEmpty` -> "No activity yet"
- No checks: `detail.checkRuns.isEmpty` -> checks section hidden
- No file changes: `files.isEmpty` -> emptyView ("NO FILE CHANGES")
- No file selected: `selectedPath == nil` -> "SELECT A FILE"
- No synopsis: `synopsis == nil && !isLoading` -> "No synopsis available"
- No patch: `file.patch == nil` -> "Binary file or diff too large"
- No labels available: `availableLabels.isEmpty` -> label filter hidden
- No authors available: `availableAuthors.isEmpty` -> author filter hidden

### Error States
- API error: `store.state.error != nil` -> ErrorBannerView with pulsing icon
- Detail load failure: `detail == nil && !isLoadingDetail` -> errorView
- Diff load failure: `error != nil` in DiffPanelView -> error message + Retry button
- Account verification failure: `error != nil` in AccountSetupView -> red error text
- Auth failure: APIError.unauthorized
- Rate limited: APIError.rateLimited(resetAt:)

### Data States
- Single PR, multiple PRs
- PRs across multiple repos (grouped display)
- PR with all review states: approved, changes requested, commented, dismissed, pending
- PR with CI statuses: success, failure, pending, error, unknown
- PR mergeable states: mergeable, conflicting, unknown
- PR states: open, merged, closed
- Draft PR (isDraft: true)
- PR with labels (1-5+)
- PR with merge conflicts
- Large PR (>1000 lines changed)
- Old PR (>5 days, high urgency score)
- Pinned PRs (separate section)
- Collapsed/expanded repo groups
- Active filters (each PRFilter case)
- Active label filters (include + exclude)
- Active author filters (include + exclude)
- Search query active
- Multiple accounts

---

## D. Accessibility Identifiers Needed

### Dashboard

| View | Identifier | Purpose |
|------|-----------|---------|
| `DashboardView` | `dashboard` | Root dashboard container |
| `DashboardHeaderBar` | `dashboardHeader` | Header bar container |
| Refresh button | `refreshButton` | Trigger manual refresh |
| Pin/Unpin button | `pinButton` | Toggle window pinning |
| Settings button | `settingsButton` | Open settings window |
| Blocked-by-me badge | `blockedByMeBadge` | Summary count badge |
| Owned-by-me badge | `ownedByMeBadge` | Summary count badge |
| Ready-for-QA badge | `readyForQABadge` | Summary count badge |
| `FilterBar` | `filterBar` | Filter bar container |
| Each filter chip | `filterChip_\(filter.rawValue)` | Individual filter buttons |
| `SearchBar` | `searchBar` | Search field container |
| Search text field | `searchField` | Text input for search |
| Search clear button | `searchClearButton` | Clear search text |
| `LabelFilterView` | `labelFilter` | Label filter section |
| Label toggle header | `labelFilterToggle` | Expand/collapse label filter |
| Label clear button | `labelFilterClear` | Clear all label filters |
| Each label chip | `labelChip_\(name)` | Individual label toggle |
| `AuthorFilterView` | `authorFilter` | Author filter section |
| Author toggle header | `authorFilterToggle` | Expand/collapse author filter |
| Author clear button | `authorFilterClear` | Clear all author filters |
| Each author chip | `authorChip_\(name)` | Individual author toggle |
| `noAccountView` | `noAccountView` | No accounts state |
| Open Settings button | `noAccountOpenSettings` | Navigate to settings |
| `emptyStateView` | `emptyStateView` | Empty/inbox zero state |
| `noMatchView` | `noMatchView` | No filter matches state |
| `ErrorBannerView` | `errorBanner` | Error display |
| Pinned section | `pinnedSection` | Pinned PRs header |
| Repo group header | `repoHeader_\(repoName)` | Collapsible repo header |
| PR row | `prRow_\(pr.id)` | Individual PR row |

### PR Detail

| View | Identifier | Purpose |
|------|-----------|---------|
| `PRDetailView` | `prDetail` | Detail view container |
| Back button | `detailBackButton` | Navigate back |
| State badge | `prStateBadge` | OPEN/MERGED/CLOSED badge |
| PR title | `prDetailTitle` | PR title text |
| Head branch | `headBranch` | Source branch label |
| Base branch | `baseBranch` | Target branch label |
| Open in GitHub button | `openInGitHub` | External link |
| `SynopsisCard` | `synopsisCard` | AI synopsis container |
| Synopsis loading | `synopsisLoading` | Loading state |
| Synopsis summary | `synopsisSummary` | Summary text |
| Checks section | `checksSection` | CI checks list |
| Each check row | `checkRun_\(name)` | Individual check |
| Activity feed | `activityFeed` | Activity timeline |
| Detail loading | `detailLoading` | Loading state |
| Detail error | `detailError` | Error state |

### Diff Panel

| View | Identifier | Purpose |
|------|-----------|---------|
| `DiffPanelView` | `diffPanel` | Diff panel container |
| `FileListSidebar` | `fileListSidebar` | File list container |
| Each file row | `fileRow_\(path)` | Individual file entry |
| `DiffContentView` | `diffContent` | Diff display area |
| File header | `diffFileHeader` | Current file header |
| Diff loading | `diffLoading` | Loading state |
| Diff error | `diffError` | Error state |
| Retry button | `diffRetryButton` | Retry after error |
| No selection | `diffNoSelection` | No file selected state |
| `InlineCommentThread` | `commentThread_\(id)` | Comment thread container |
| Thread toggle | `threadToggle_\(id)` | Expand/collapse thread |
| `CommentComposer` | `commentComposer` | Reply input area |
| Reply text editor | `replyTextEditor` | Reply text input |
| Reply button | `replyButton` | Submit reply |

### Actions

| View | Identifier | Purpose |
|------|-----------|---------|
| Approve button | `approveButton` | Approve PR action |
| Merge button | `mergeButton` | Open merge options |
| Request Changes button | `requestChangesButton` | Open changes popover |
| Squash option | `mergeOption_squash` | Select squash merge |
| Merge option | `mergeOption_merge` | Select merge commit |
| Rebase option | `mergeOption_rebase` | Select rebase merge |
| Changes comment field | `changesCommentField` | Request changes text |
| Changes submit | `changesSubmitButton` | Submit change request |

### Settings

| View | Identifier | Purpose |
|------|-----------|---------|
| `SettingsView` | `settingsWindow` | Settings container |
| Accounts tab | `settingsTab_accounts` | Tab selector |
| AI tab | `settingsTab_ai` | Tab selector |
| Prompt tab | `settingsTab_prompt` | Tab selector |
| General tab | `settingsTab_general` | Tab selector |
| Changelog tab | `settingsTab_changelog` | Tab selector |
| Help tab | `settingsTab_help` | Tab selector |
| Add Account button | `addAccountButton` | Open add account sheet |
| Account row | `accountRow_\(username)` | Individual account entry |
| Remove account button | `removeAccount_\(username)` | Delete account |
| Host type picker | `hostTypePicker` | Cloud/Enterprise selector |
| Token field | `tokenField` | PAT input |
| Enterprise host field | `enterpriseHostField` | Enterprise URL input |
| Cancel button | `addAccountCancel` | Cancel add account |
| Add Account submit | `addAccountSubmit` | Submit new account |
| Verify spinner | `verifySpinner` | Token verification state |
| Ollama toggle | `ollamaToggle` | Enable/disable Ollama |
| OpenAI toggle | `openAIToggle` | Enable/disable OpenAI |
| Hotkey recorder | `hotkeyRecorder` | Shortcut input |
| Hotkey reset | `hotkeyReset` | Reset to default shortcut |

---

## E. Mocking Strategy

### Protocol-Based Injection

The app uses concrete `GitHubGraphQLClient` (an `actor`) directly in `DashboardStore` and `ActionHandler`. For XCUITests, we cannot inject mocks at the code level since UI tests run against the compiled app binary.

**Recommended approach: Launch argument-driven mock mode.**

```
// Launch arguments the app should recognize:
--uitesting                    // Enable UI test mode
--mock-empty                   // Return empty PR list
--mock-error                   // Simulate API error
--mock-loaded                  // Return fixture PR data
--mock-no-account              // No accounts configured
--mock-detail-error            // Simulate detail fetch failure
--mock-diff-data               // Return fixture diff data
--mock-diff-error              // Simulate diff fetch failure
```

### Implementation

1. **AppDelegate** checks `ProcessInfo.processInfo.arguments` for `--uitesting`
2. When in UI test mode, replace `GitHubGraphQLClient` with a `MockGraphQLClient` that returns fixture data
3. Replace `KeychainManager` with in-memory storage (avoid Keychain prompts in CI)
4. Replace `AccountManager` with pre-configured mock accounts (or empty, based on launch args)

### Fixture Data

Create `PRWidgetUITests/Fixtures/` with:
- `MockPRData.swift` — factory methods for `PullRequest` instances covering all states
- `MockDetailData.swift` — factory for `PRDetail` with comments, events, checks
- `MockDiffData.swift` — factory for `PRFileDiff` with patches and review threads
- Use static JSON fixtures decoded in-process, or struct factories

### Mock Granularity

| Scenario | Launch Args | Expected State |
|----------|-------------|---------------|
| Empty dashboard | `--uitesting --mock-empty` | "INBOX ZERO" view |
| No accounts | `--uitesting --mock-no-account` | "NO ACCOUNTS" view |
| Loaded with PRs | `--uitesting --mock-loaded` | PR list with repo groups |
| API error | `--uitesting --mock-error` | ErrorBannerView visible |
| Detail loaded | `--uitesting --mock-loaded` | Detail view with all sections |
| Detail error | `--uitesting --mock-detail-error` | "Failed to load details" |
| Diff loaded | `--uitesting --mock-diff-data` | File list + diff content |
| Diff error | `--uitesting --mock-diff-error` | Error with Retry button |

---

## F. Test File Organization

```
PRWidgetUITests/
├── TEST_PLAN.md                       # This file
├── Helpers/
│   ├── XCUIApplication+Launch.swift   # Launch helpers with mock args
│   ├── AccessibilityIDs.swift         # Shared identifier constants
│   └── PRWidgetScreen.swift           # Page object for dashboard
├── Fixtures/
│   └── (JSON fixture files if needed)
├── Tests/
│   ├── DashboardUITests.swift         # Dashboard states and navigation
│   ├── FilterUITests.swift            # Filter bar, search, label/author filters
│   ├── PRRowUITests.swift             # PR row display and context menu
│   ├── PRDetailUITests.swift          # Detail view states and content
│   ├── DiffPanelUITests.swift         # Diff panel states and interactions
│   ├── ActionsUITests.swift           # Approve, merge, request changes
│   ├── SettingsUITests.swift          # Settings tabs and account management
│   ├── WindowUITests.swift            # Panel show/hide, pin/unpin, escape
│   └── AccessibilityUITests.swift     # VoiceOver labels and navigation
```

### Page Object Pattern

Each screen gets a page object class wrapping XCUIElement queries:

```swift
struct DashboardScreen {
    let app: XCUIApplication

    var refreshButton: XCUIElement { app.buttons["refreshButton"] }
    var settingsButton: XCUIElement { app.buttons["settingsButton"] }
    var pinButton: XCUIElement { app.buttons["pinButton"] }
    var filterBar: XCUIElement { app.otherElements["filterBar"] }
    var searchField: XCUIElement { app.textFields["searchField"] }
    var noAccountView: XCUIElement { app.otherElements["noAccountView"] }
    var emptyStateView: XCUIElement { app.otherElements["emptyStateView"] }
    var errorBanner: XCUIElement { app.otherElements["errorBanner"] }

    func filterChip(_ name: String) -> XCUIElement {
        app.buttons["filterChip_\(name)"]
    }

    func prRow(_ id: String) -> XCUIElement {
        app.buttons["prRow_\(id)"]
    }

    func repoHeader(_ name: String) -> XCUIElement {
        app.otherElements["repoHeader_\(name)"]
    }
}
```

---

## G. Priority Order

### P0 — Critical Path (Write First)

1. **DashboardUITests: App launch and basic display**
   - App launches, panel appears
   - Dashboard header bar visible with title, refresh, pin, settings buttons
   - Validates the core happy path

2. **DashboardUITests: Empty states**
   - No accounts -> "NO ACCOUNTS" view + "Open Settings" button
   - No PRs -> "INBOX ZERO" view
   - Ensures graceful degradation

3. **DashboardUITests: PR list with data**
   - PRs appear grouped by repo
   - PR rows show title, repo#number, urgency badge, status badge, line counts
   - Multiple repos display with correct grouping

4. **FilterUITests: Filter bar interaction**
   - Tap each filter chip, verify active state changes
   - Verify PR list updates based on filter

5. **PRDetailUITests: Navigate to detail and back**
   - Tap PR row -> detail view appears
   - Back button returns to dashboard
   - Detail header shows correct PR info

### P1 — Important Features

6. **FilterUITests: Search**
   - Type in search bar, PR list filters
   - Clear search, list restores

7. **FilterUITests: Label filter include/exclude**
   - Expand label filter
   - Tap label to include (yellow)
   - Verify filtering works
   - Clear filters

8. **PRDetailUITests: Detail content states**
   - Loading state visible
   - Synopsis card displays
   - Checks section visible
   - Activity feed with comments and events
   - Error state when detail fails to load

9. **SettingsUITests: Open settings and navigate tabs**
   - Settings button opens settings window
   - All 6 tabs accessible
   - Basic content visible in each tab

10. **SettingsUITests: Account management**
    - "Add Account..." button opens sheet
    - Host type picker switches between Cloud/Enterprise
    - Cancel dismisses sheet
    - Token field accepts input

### P2 — Extended Coverage

11. **DiffPanelUITests: Diff panel display**
    - File list sidebar shows files
    - Selecting file shows diff content
    - Line additions (green) and deletions (red) display correctly

12. **PRRowUITests: Context menu**
    - Right-click PR row shows context menu
    - Menu items: Pin, Open in Browser, Copy URL, Copy Branch, Labels

13. **WindowUITests: Panel behavior**
    - Escape key hides panel
    - Pin/unpin toggles persistence behavior

14. **DiffPanelUITests: Comment threads**
    - Inline comment threads appear at correct lines
    - Expand/collapse thread
    - Reply composer visible

15. **ActionsUITests: Quick actions**
    - Approve button triggers action
    - Merge button opens method popover
    - Request Changes button opens comment popover

### P3 — Polish

16. **FilterUITests: Author filter**
    - Same mechanics as label filter

17. **DashboardUITests: Repo collapse/expand**
    - Click header to collapse/expand
    - Verify PR rows hidden/shown

18. **DashboardUITests: Pinned PRs**
    - Pin a PR via context menu
    - Pinned section appears at top
    - Unpin removes from section

19. **AccessibilityUITests: VoiceOver**
    - All interactive elements have accessibility labels
    - Logical focus order

20. **SettingsUITests: AI configuration**
    - Toggle Ollama/OpenAI
    - Verify config fields appear/disappear

---

## H. CI Considerations

- XCUITests run against a built `.app` bundle
- Use `--uitesting` launch argument to enable mock mode (no network, no Keychain)
- Tests should be deterministic: all data comes from fixtures
- Avoid timing-dependent assertions; use `waitForExistence(timeout:)` generously
- The app is an LSUIElement (no dock icon) with NSPanel — XCUITest may need special handling for non-standard window management
- Consider using `XCTAttachment` for screenshots on failure
- Menu bar interactions may require `XCUIApplication(bundleIdentifier:)` for the menu extras

---

## I. Known Testing Challenges

1. **NSPanel / FloatingPanel**: XCUITest may not detect non-activating panels as standard windows. May need to query via `app.windows` or `XCUIApplication.windows.element(boundBy: 0)`.

2. **Menu Bar Status Item**: Clicking the menu bar icon requires finding the status item. macOS 14+ may require using `menuBarItem` queries or System Events.

3. **Context Menus**: Right-click context menus are standard AppKit constructs and should be queryable via `app.menuItems` after right-clicking.

4. **Global Hotkey**: Carbon hotkey API cannot be triggered via XCUITest. Test the UI response (panel visibility toggle) by other means.

5. **Separate Windows**: Settings and Diff panels open as separate `NSWindow` instances. XCUITest can query `app.windows.count` and interact with elements across windows.

6. **Drag and Drop**: Repo header drag-to-reorder uses SwiftUI `.draggable`/`.dropDestination`. XCUITest drag operations on these may be unreliable; consider lower priority.

7. **Cmd+Click Modifiers**: Label/author filter Cmd+click for exclude mode reads `NSEvent.modifierFlags`. XCUITest can simulate modifier keys but this may be fragile.
