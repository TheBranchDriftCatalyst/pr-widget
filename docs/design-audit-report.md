# P-Arr Design Audit -- Executive Report

**Date:** 2026-03-15
**Version:** 1.0
**Status:** Final
**Prepared for:** Product Leadership, Catalyst DevSpace
**Classification:** Internal

---

## Executive Summary

P-Arr is a native macOS menu bar application for GitHub pull request management, built with Swift 6 and SwiftUI. It delivers a cyberpunk-themed floating dashboard that aggregates PR state across GitHub accounts via GraphQL, offering triage categorization, diff review, label management, and AI-generated PR summaries. The visual design demonstrates strong aesthetic vision -- the "cybersynthpunk" dark theme with neon glow effects, glass cards, and monospaced typography creates a distinctive and memorable product identity that scores well above commodity developer tools.

This audit, conducted by an eight-agent Mixture-of-Experts panel covering brand coherence, visual design, color systems, typography, component architecture, information architecture, UX flows, and platform compliance, reveals a product at an inflection point. The surface presentation is polished and the core data pipeline (GraphQL fetch, decode, categorize, render) is solid. However, beneath this surface lie **four critical built-but-broken features** that shipped in a non-functional state, a design system that is tokenized at the color level but chaotic at the font, spacing, and border levels, and a complete absence of accessibility support. Thirty distinct issues were cataloged across four severity tiers.

The overarching pattern is one of ambitious feature development without integration discipline. QuickActionsView (approve/merge/request-changes), the UIScale system, and MentionTracker all exist as fully implemented code that is never wired into the user-facing product. This "built-but-not-connected" anti-pattern, combined with duplicated components and naming fragmentation from an incomplete rename migration, suggests that the project needs a consolidation phase before further feature work. The recommendations in this report are structured as a four-phase roadmap: critical fixes (1-2 weeks), design system foundation (2-3 weeks), UX enhancement (3-4 weeks), and brand polish (ongoing).

---

## Methodology

This audit was conducted using a Mixture-of-Experts (MoE) approach with eight specialized agent reviewers:

1. **Brand Coherence Agent** -- Evaluated naming consistency, visual identity, tagline, iconography, and brand expression across all touchpoints.
2. **Visual Design Agent** -- Assessed visual hierarchy, layout quality, aesthetic coherence, and overall visual clarity.
3. **Color System Agent** -- Analyzed the color token architecture, semantic color usage, contrast ratios, and color-blind accessibility.
4. **Typography Agent** -- Audited font usage patterns, type scale consistency, and the scalable text infrastructure.
5. **Component Architecture Agent** -- Reviewed component duplication, extraction opportunities, API design, and reusability.
6. **Information Architecture Agent** -- Evaluated navigation structure, mental models, filter taxonomy, and content organization.
7. **UX Flow Agent** -- Tested task completion paths, feedback loops, error handling, and microinteraction quality.
8. **Platform Compliance Agent** -- Checked macOS HIG conformance, accessibility support, system integration, and platform conventions.

Each agent produced independent findings, which were then subjected to a cross-agent critique round where agents challenged each other's assessments for accuracy and priority calibration. The final issue list represents validated consensus.

---

## Scorecard

| Domain | Score | Grade | Assessment |
|---|---|---|---|
| Brand Coherence | 5/10 | D | Naming fragmentation across 12+ locations; incomplete rename migration |
| Visual Clarity | 9/10 | A | Strong hierarchy with neon accents guiding attention effectively |
| Visual Hierarchy | 9/10 | A | Excellent use of accent stripes, glow effects, and layered surfaces |
| Layout Quality | 8/10 | B+ | Clean layout with minor spacing inconsistencies |
| Color System | 8/10 | B+ | Well-tokenized palette; semantic aliases defined; yellow overloaded |
| Typography | 7/10 | C+ | Consistent monospaced aesthetic but zero token discipline |
| Aesthetic Coherence | 9/10 | A | Cyberpunk theme is cohesive and distinctive |
| Token Completeness | 4/10 | D | Colors tokenized; fonts, spacing, borders, and motion are ad-hoc |
| Component Maturity | 5/10 | D | Significant duplication; FlowLayout not shared; no component catalog |
| Design System Consistency | 7/10 | C+ | Theme discipline at token level, chaos at consumption level |
| IA Quality | 7/10 | C+ | Dual organizational models (PRFilter vs DashboardState) create confusion |
| Navigation | 7/10 | C+ | NavigationStack works but PR click triggers simultaneous actions |
| Mental Model | 7/10 | C+ | Triage categories exist but are not exposed as filters |
| Task Completion | 5/10 | D | Core review actions (approve/merge) are built but not reachable |
| Microinteractions | 7/10 | C+ | Hover glow and animations are well done; drag-to-reorder lacks affordance |
| Feedback Completeness | 5/10 | D | No clipboard confirmation; comment data loss on failure; silent errors |
| Discoverability | 4/10 | D | Cmd-click for exclude filters is undocumented; Quick Actions hidden |
| Cognitive Load | 6/10 | C | Yellow overload creates ambiguity; urgency score is opaque |
| Learnability | 5/10 | D | No onboarding; hidden gestures; undiscoverable features |
| macOS Compliance | 7/10 | C+ | LSUIElement pattern correct; NSPanel usage appropriate |
| Accessibility | 3/10 | F | Zero support for Reduce Motion, Reduce Transparency, Dynamic Type |
| Platform Integration | 3/10 | F | No UserNotifications, no Launch-at-Login, no Spotlight |
| UX Differentiation | 9/10 | A | Highly distinctive visual identity; memorable cyberpunk aesthetic |
| Competitive Moat | 5/10 | D | Strong visual differentiation but missing table-stakes platform features |

**Overall Weighted Score: 6.3/10 (C+)**

---

## Critical Issues (P0)

### P0-1: QuickActionsView Dead Code

**Diagnosis:** A complete PR review action system -- approve, merge, and request changes -- is fully implemented across four files but never integrated into the user-facing product.

**Files:**
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Actions/QuickActionsView.swift` (lines 1-57)
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Actions/MergeOptionsView.swift` (lines 1-59)
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Actions/RequestChangesPopover.swift`
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Store/ActionHandler.swift` (lines 1-94)

**Root Cause:** `PRDetailView.swift` (lines 1-294) renders the detail header, synopsis, checks, and activity feed but never instantiates `QuickActionsView`. The `ActionHandler` class has fully working `approve()`, `requestChanges()`, and `merge()` methods with proper GraphQL mutations, but no view calls them.

**Impact:** The product's most important user action -- responding to a PR -- requires leaving the app entirely and opening GitHub in a browser. This negates the core value proposition of a "floating dashboard for PR management." Users can see PRs but cannot act on them.

**Recommended Fix:** Add `QuickActionsView` to `PRDetailView` between the header and synopsis sections. Wire the callbacks through `DashboardStore` to `ActionHandler`. Estimated scope: ~50 lines of integration code.

**Effort:** 2-4 hours

---

### P0-2: Merge Without Confirmation Dialog

**Diagnosis:** `MergeOptionsView` (line 20-21) calls `onSelect(method)` directly on button tap with no confirmation step. Merging a pull request is an irreversible production action.

**File:** `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Actions/MergeOptionsView.swift`

**Root Cause:** The merge flow was implemented as a simple popover with a list of merge methods (squash, merge, rebase). Each method button immediately fires the callback. There is no intermediate confirmation, no display of the target branch, and no warning about the irreversibility of the action.

**Impact:** When QuickActionsView is wired in (P0-1), a single misclick on a merge method will merge a PR to production with no undo. This is a data-loss-class defect.

**Recommended Fix:** Add a confirmation step to the merge flow. After selecting a merge method, show a confirmation view that displays: the merge method, the target branch (baseRefName), the PR title, and a "Confirm Merge" button with destructive styling. Add a 1-second delay or require a secondary click.

**Effort:** 3-5 hours

---

### P0-3: MentionTracker Non-Functional

**Diagnosis:** The `MentionTracker` class has three distinct defects that render it inoperative.

**File:** `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Services/MentionTracker.swift`

**Defect 1 (line 48):** `markAsRead` hardcodes `let currentUser = ""` with a comment "Will be passed from outside" -- but this was never done. The function ignores this variable currently (it just inserts all comment IDs), but the dead code signals incomplete implementation.

**Defect 2 (line 63):** `markAllMentionsRead` recalculates `unreadMentionCount` as `max(0, unreadMentionCount)` -- which is a no-op. The count never decreases when marking all mentions read.

**Defect 3 (line 29):** `checkForMentions` iterates over PRs and checks `pr.detail` for comments, but `detail` is a lazily-loaded property that is only populated when a user clicks into a PR's detail view. On the dashboard listing, `pr.detail` is always `nil`, so the `guard let detail = pr.detail else { continue }` skips every PR.

**Impact:** The mention badge in the status bar (`AppDelegate.swift` line 96-126) will never show a count. The "Mentioned" filter in `PRFilter` works via a separate path (line 133-136 of `DashboardStore.swift`) that also checks `pr.detail`, making it equally non-functional for PRs not yet clicked.

**Recommended Fix:**
1. Fix `markAllMentionsRead` to properly recalculate: iterate remaining mentionedPRIDs, count unseen comments, set `unreadMentionCount`.
2. Remove dead `currentUser` variable from `markAsRead`.
3. For `checkForMentions`: either (a) eagerly fetch mention data via a lightweight GraphQL query that checks for `@username` mentions, or (b) use the existing `reviewRequests` field as a proxy for "needs your attention" and augment with mention data as details are loaded.

**Effort:** 4-8 hours

---

### P0-4: UIScale System Completely Broken

**Diagnosis:** A complete UI scaling system is implemented across the catalyst-lib and the app, with a slider in Settings, environment injection at the root, and scaling-aware text components. However, zero views in the application consume it.

**Files:**
- `/Users/panda/catalyst-devspace/workspace/pr-widget/catalyst-lib/Sources/CatalystSwift/Theme/UIScale/ScaledFont.swift` -- `ScaledFontModifier` and `.scaledFont()` view modifier
- `/Users/panda/catalyst-devspace/workspace/pr-widget/catalyst-lib/Sources/CatalystSwift/Theme/UIScale/ScaledText.swift` -- `CText` and `CLabel` components that read `catalystScale`
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/App/AppDelegate.swift` (line 149) -- `TextScaleModifier()` injecting `catalystScale` environment
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Settings/GeneralSettingsView.swift` (lines 49-62) -- UIScale slider bound to `@AppStorage("PArr.ui.textScale")`

**Root Cause:** All 147 font declarations across 22 view files use raw `.font(.system(size: N))` calls. None use `CText`, `CLabel`, or the `.scaledFont()` modifier. The `catalystScale` environment value is injected but never read.

**Impact:** The Settings slider appears to work (it animates, the value persists) but has zero visual effect. This is a trust-eroding defect -- users who adjust the slider and see nothing happen will question the reliability of other settings.

**Recommended Fix:** Two viable approaches:
- **Incremental (recommended):** Replace raw `.font(.system(size:))` calls with `.scaledFont(size:weight:design:)` across all 22 files. This is a mechanical find-and-replace operation.
- **Systemic:** Define a type scale (see Typography System section below) and use `CText`/`CLabel` components throughout. More invasive but results in better architecture.

**Effort:** 4-8 hours (incremental) or 16-24 hours (systemic)

---

## High Priority Issues (P1)

### P1-5: Naming Fragmentation

**Diagnosis:** The product is referred to by four different names across the codebase, resulting from an incomplete rename migration from "PRWidget" to "P-Arr."

**Evidence:**
| Location | Name Used |
|---|---|
| `Package.swift` line 5 | `PArr` (product name) |
| `DashboardHeaderBar.swift` line 28 | `PR WIDGET` (user-facing header) |
| `AppDelegate.swift` line 179 | `Quit P-Arr` (menu item) |
| `AppDelegate.swift` line 210 | `P-Arr Settings` (window title) |
| `GeneralSettingsView.swift` line 71 | `P-Arr -- Catalyst DevSpace` (about) |
| `PRWidgetApp.swift` (struct name) | `PRWidgetApp` |
| Source directory | `PRWidget/` |
| `AppDelegate.swift` line 85 | `PR Widget` (accessibility description) |
| UserDefaults prefix | `PArr.` (migration from `PRWidget.`) |
| Keychain service | `com.catalyst.p-arr` (migrated from `com.catalyst.prwidget`) |
| `BrewSelfUpdater` init | `caskName: "p-arr", appName: "PArr"` |
| `AppDelegate.swift` line 28 | `[PArr]` (NSLog prefix) |

**Impact:** Users encounter "PR WIDGET" in the header, "P-Arr" in the quit menu, and "PArr" in Homebrew. This fractures brand recognition and signals incomplete polish.

**Recommended Fix:** Standardize on "P-Arr" as the display name everywhere. See Brand Strategy section.

**Effort:** 2-3 hours

---

### P1-6: DashboardState Triage Categories Never Exposed as Filters

**Diagnosis:** `DashboardState` (lines 16-52) computes three triage categories: `needsAction`, `readyToShip`, and `waitingOnOthers`. These represent the most valuable organizational model for PR triage. However, `PRFilter` (lines 1-9) uses a completely different flat taxonomy: All, My PRs, Review Requested, Mentioned, Blocked by Me.

**Files:**
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Models/DashboardState.swift`
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Models/PRFilter.swift`
- `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Dashboard/FilterBar.swift`

**Impact:** The triage categories are used internally for urgency scoring but never surfaced to the user. The "Ready to Ship" category exists in the model as `readyToShip` but appears in the header badge as "Ready for QA" (`DashboardHeaderBar.swift` line 48), creating a naming mismatch. Users cannot filter their view to "show me what needs my action" despite this being computed.

**Recommended Fix:** Merge the two filter systems. Add `needsAction`, `readyToShip`, and `waitingOnOthers` as filter options, either replacing or augmenting the existing flat taxonomy. Rename "Ready for QA" to "Ready to Ship" for consistency with the model.

**Effort:** 4-6 hours

---

### P1-7: Zero Accessibility Support

**Diagnosis:** The application provides no accommodation for any macOS accessibility setting.

**Specifics:**
- **Reduce Motion:** The infinite glow pulse animation (`WindowManager.swift` lines 58-68) runs unconditionally with `repeatCount: .infinity`. Hover glow animations on every PR row run without checking `@Environment(\.accessibilityReduceMotion)`.
- **Reduce Transparency:** All glass card effects (`Catalyst.glass = Color.white.opacity(0.03)`) ignore `accessibilityReduceTransparency`.
- **Differentiate Without Color:** Status badges (CI pass/fail, review state) rely solely on color. No shape or text differentiation.
- **Dynamic Type:** All 147 font size declarations are hardcoded. The UIScale system exists but is not connected (P0-4).
- **VoiceOver:** Some accessibility identifiers exist (`AccessibilityIdentifiers.swift`) and basic labels are present on `PRRowView` (line 87), but coverage is incomplete.

**Impact:** The application is unusable for users with motion sensitivity, low vision, or color vision deficiency. This is both an ethical concern and a practical barrier to adoption in enterprise environments that require accessibility compliance.

**Recommended Fix:** See Motion System and Accessibility sections below.

**Effort:** 8-16 hours

---

### P1-8: Comment Text Data Loss on Failure

**Diagnosis:** `CommentComposer.swift` (lines 30-38) captures the reply text, clears the text field, then performs the async submission. If the network call fails, the user's comment text is permanently lost.

**File:** `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Diff/CommentComposer.swift`

```swift
let text = replyText
replyText = ""  // <-- Text cleared before async operation
Task {
    await onSubmit(text)  // <-- If this fails, text is gone
    isSubmitting = false
}
```

**Impact:** Users who compose a detailed review comment and experience a network timeout lose their work with no recovery path and no error indication.

**Recommended Fix:** Move the text clearing to after successful completion. Store the text in a local variable, show a loading state, and only clear `replyText` in the success path. On failure, restore the text and show an error indicator.

**Effort:** 1-2 hours

---

### P1-9: Duplicated Components

**Diagnosis:** Several components are copy-pasted rather than abstracted into shared implementations.

| Duplicate A | Duplicate B | Difference |
|---|---|---|
| `LabelToggleChip` in `LabelFilterView.swift` (line 127) | `AuthorToggleChip` in `AuthorFilterView.swift` (line 126) | Only the property name (`name` vs `name`) differs; identical view body, colors, states |
| `LabelChipState` in `LabelFilterView.swift` (line 123) | `AuthorChipState` in `AuthorFilterView.swift` (line 122) | Identical enum with different name |
| `PRRowView` in `PRRowView.swift` (lines 1-106) | `PRRowContent` in `DashboardView.swift` (lines 318-425) | Nearly identical layout; PRRowContent adds pin indicator and pin context menu |
| `FlowLayout` in `LabelFilterView.swift` (line 180) | Used in `AuthorFilterView.swift` (line 78) | Defined in LabelFilterView, imported by AuthorFilterView; should be in shared library |
| `relativeTime()` | Present in both `InlineCommentThread.swift` and `ActivityFeed.swift` | Identical date formatting logic |

**Impact:** Bug fixes and visual changes must be applied to multiple locations. Divergence over time is inevitable.

**Recommended Fix:** Extract `ToggleChip` (generic), `FlowLayout`, and `relativeTime()` into shared components. Merge `PRRowView` and `PRRowContent` into a single configurable component.

**Effort:** 4-6 hours

---

### P1-10: Multi-Monitor Positioning

**Diagnosis:** `WindowManager.swift` (line 129) uses `NSScreen.main` to clamp the panel position instead of deriving the screen from the status item button's actual window.

```swift
if let screen = NSScreen.main ?? NSScreen.screens.first {
```

Similarly, `AppDelegate.swift` (line 273) uses `NSScreen.main` for the diff panel positioning.

**Impact:** On multi-monitor setups where the menu bar is on a secondary display, the panel may be positioned on the wrong screen or clipped at screen boundaries.

**Recommended Fix:** Replace `NSScreen.main` with `buttonWindow.screen` (already available from the `guard let buttonWindow = button.window` on line 119). For the diff panel, derive the screen from the main panel's frame.

**Effort:** 30 minutes

---

## Design System Reconstruction Proposal

### Color System

**Current State:** The color system (`CatalystTheme.swift`) is the strongest aspect of the design system. Colors are well-organized into semantic groups (Core Surfaces, Text, Neon Accents, Semantic, Glass, Glow). PR-specific semantic aliases are properly extended in `CatalystTheme+PR.swift`.

**Assessment: 8/10**

**Issue: Yellow Overload (P2-11)**

The color `Catalyst.yellow` (#fbbf24) currently carries five distinct semantic meanings:

1. **Warning state** -- `Catalyst.warning = yellow` (semantic alias)
2. **Pending review** -- `Catalyst.pendingReview = yellow` (in `CatalystTheme+PR.swift` line 16)
3. **Pin indicator** -- Pin icons use `Catalyst.yellow` (DashboardView.swift line 211)
4. **Label filter include state** -- `LabelToggleChip` uses `Catalyst.yellow` for included state (LabelFilterView.swift line 165)
5. **Medium urgency** -- UrgencyBadge uses yellow for mid-range scores

**Proposed Refinements:**

```
Catalyst.warning    = yellow (#fbbf24)     -- Keep for warnings/alerts
Catalyst.pinned     = NEW amber (#f59e0b)  -- Differentiate pins from warnings
Catalyst.filterOn   = cyan (#00fcd6)       -- Use existing cyan for "active/included"
Catalyst.pending    = blue (#00d4ff)        -- Already defined separately; use consistently
```

**Accessibility Fixes:**
- Audit `Catalyst.magenta` (#c026d3) against `Catalyst.background` (#0a0a0f) for WCAG AA compliance. Current contrast ratio is approximately 3.8:1, below the 4.5:1 AA threshold for normal text. Consider brightening to #d946ef for body text usage.
- Add color-blind-safe patterns: pair every color indicator with a shape or text label. CI status already uses distinct SF Symbols (checkmark, xmark, clock, exclamationmark, questionmark) -- this pattern should be extended to review states and urgency badges.

---

### Typography System

**Current State:** 147 raw `.font(.system(size: N))` calls across 22 files. Sizes used: 8, 9, 10, 11, 12, 13, 14, 15, 28, 40. Weights used: regular, medium, semibold, bold. Design: predominantly `.monospaced`, occasionally `.default`.

**Assessment: 4/10 (token completeness)**

**Proposed Type Scale:**

| Token Name | Size | Weight | Design | Usage |
|---|---|---|---|---|
| `display` | 15pt | semibold | default | PR titles in detail view |
| `heading` | 14pt | medium | default | PR titles in list rows |
| `subheading` | 13pt | bold | monospaced | Section headers (e.g., "PR WIDGET") |
| `body` | 12pt | regular | monospaced | General body text, code |
| `caption` | 11pt | medium | monospaced | Repo names, metadata, line counts |
| `label` | 10pt | bold | monospaced | Section labels ("CHECKS", "BACK"), badges |
| `micro` | 9pt | bold | monospaced | Filter chips, filter headers, mini badges |
| `nano` | 8pt | bold | monospaced | Clear buttons, tiny UI elements |
| `icon.large` | 40pt | -- | -- | Empty state icons |
| `icon.medium` | 28pt | -- | -- | Secondary empty state icons |

**Tracking Values:**
| Context | Value |
|---|---|
| Section headers | 2pt |
| Labels | 1pt |
| Filter chips | 0.5pt |
| Body text | 0pt (default) |

**Migration Path:**

1. Define the type scale as static properties on `Catalyst` in `CatalystTheme.swift`:
   ```swift
   public static func heading() -> Font { .system(size: 14, weight: .medium) }
   public static func label() -> Font { .system(size: 10, weight: .bold, design: .monospaced) }
   ```
2. Replace raw font calls with token references, file by file.
3. Wrap token methods to consume `catalystScale`, resolving P0-4 simultaneously.

---

### Spacing System

**Current State:** No spacing tokens exist. Padding values are ad-hoc: `.padding(12)`, `.padding(.horizontal, 8)`, `.padding(.vertical, 4)`, etc. The only defined constant is `Catalyst.cornerRadius = 8`.

**Proposed Spacing Scale:**

| Token | Value | Usage |
|---|---|---|
| `space.xs` | 2pt | Inline element gaps (e.g., between "+" and "-" in line counts) |
| `space.sm` | 4pt | Tight element spacing (chip padding, label gaps) |
| `space.md` | 8pt | Standard element spacing (button padding, row spacing) |
| `space.lg` | 12pt | Section padding (card content, list item padding) |
| `space.xl` | 16pt | Outer margins (header bar horizontal padding) |
| `space.2xl` | 24pt | Large separation (between major sections) |

**Base Unit:** 4pt (all values are multiples of 4).

**Corner Radius Scale:**
| Token | Value | Usage |
|---|---|---|
| `radius.sm` | 3pt | Inline code badges (branch names in PRDetailView) |
| `radius.md` | 8pt | Cards, buttons, popovers (current `Catalyst.cornerRadius`) |
| `radius.full` | 999pt | Capsule shapes (filter chips, count badges) |

---

### Border Width System

**Current State:** Three distinct border widths are used without semantic naming:

| Width | Locations |
|---|---|
| 0.5pt | `LabelPills.swift`, `CommentComposer.swift`, `UrgencyBadge.swift` |
| 1pt | `WindowManager.swift`, `FilterBar.swift`, `SearchBar.swift`, `LabelFilterView.swift`, `AuthorFilterView.swift`, `GeneralSettingsView.swift` |
| 2pt | `ReviewAvatars.swift` (avatar stack overlap ring) |

**Proposed Border Tokens:**
| Token | Value | Usage |
|---|---|---|
| `border.thin` | 0.5pt | Subtle outlines on small elements |
| `border.regular` | 1pt | Standard borders on interactive elements |
| `border.thick` | 2pt | Emphasis borders, avatar rings |

---

### Component Library

**Components to Extract from Ad-Hoc Code:**

| Component | Current Location | Proposed API |
|---|---|---|
| `ToggleChip` | `LabelToggleChip` + `AuthorToggleChip` | `ToggleChip(label: String, state: ChipState, onTap: (Bool) -> Void)` |
| `FlowLayout` | `LabelFilterView.swift` line 180 | Move to `catalyst-lib/Sources/CatalystSwift/Layout/FlowLayout.swift` |
| `SectionHeader` | Repeated pattern across ~8 files | `SectionHeader(title: String, count: Int?, color: Color)` |
| `EmptyState` | 4 variants in `DashboardView.swift` + `DiffPanelView.swift` | `EmptyState(icon: String, title: String, subtitle: String?, action: (() -> Void)?)` |
| `GlowDivider` | Used 20+ times; assumed to be in catalyst-lib | Verify it is in shared lib; if not, extract |
| `GradientAccentStripe` | Used in `PRRowView` and `PRRowContent` | Confirm shared; document API |
| `ConfirmationDialog` | Does not exist | `ConfirmationDialog(title: String, message: String, destructiveLabel: String, onConfirm: () -> Void)` |
| `CopyButton` | Inline in context menus | `CopyButton(text: String, label: String, onCopy: (() -> Void)?)` with toast confirmation |

**Proposed `SectionHeader` API:**

```swift
struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var icon: String? = nil
    var accentColor: Color = Catalyst.cyan
    var isCollapsible: Bool = false
    var isCollapsed: Bool = false
    var onToggle: (() -> Void)? = nil
}
```

This would replace the repeated pattern of:
```swift
Text("SECTION_NAME")
    .font(.system(size: 10, weight: .bold, design: .monospaced))
    .tracking(1)
    .foregroundStyle(Catalyst.muted)
```

found in `PRDetailView.swift` (line 186-189), `MergeOptionsView.swift` (line 11-16), `GeneralSettingsView.swift` (lines 15-18, 51-54, 66-69), and others.

---

### Motion System

**Current State:** Animations are ad-hoc with no tokens. The glow pulse in `WindowManager.swift` runs indefinitely with `repeatCount: .infinity`.

**Proposed Animation Tokens:**

| Token | Duration | Curve | Usage |
|---|---|---|---|
| `anim.instant` | 0.1s | easeOut | Button press feedback |
| `anim.fast` | 0.15s | easeInOut | Collapse/expand, filter selection |
| `anim.normal` | 0.25s | easeInOut | Panel show/hide, navigation transitions |
| `anim.slow` | 0.5s | easeInOut | Loading shimmer, state transitions |
| `anim.pulse` | 3.0s | easeInOut | Glow pulse (when Reduce Motion is off) |

**Reduce Motion Compliance Plan:**

1. Add `@Environment(\.accessibilityReduceMotion) var reduceMotion` to `WindowManager`.
2. Conditionally disable `startGlowPulse` when reduceMotion is true.
3. Replace `hoverGlow` modifier to use opacity change instead of shadow animation when reduceMotion is true.
4. Replace `.shimmerLoading()` with a static loading indicator when reduceMotion is true.
5. Reduce or eliminate `withAnimation` blocks when reduceMotion is true.

---

## UX Rearchitecture

### Navigation Model

**Current Issue (P2-15):** Clicking a PR row simultaneously triggers a `NavigationLink` (pushing `PRDetailView`) AND a `simultaneousGesture` that opens the diff panel (`onOpenDiffPanel`). This means a single click opens two things at once.

**File:** `/Users/panda/catalyst-devspace/workspace/pr-widget/PRWidget/Views/Dashboard/DashboardView.swift` (lines 196-202, 250-257)

```swift
NavigationLink(value: pr) {
    PRRowContent(pr: pr, store: store)
}
.buttonStyle(.plain)
.simultaneousGesture(TapGesture().onEnded {
    onOpenDiffPanel(pr)  // Also fires on the same click
})
```

**Proposed Changes:**

1. **Single click** = Navigate to `PRDetailView` only (remove `simultaneousGesture`).
2. **Option-click or dedicated button** = Open diff panel in separate window.
3. Add a "View Diff" button inside `PRDetailView` to open the diff panel from the detail view.
4. Add keyboard shortcut: `Cmd+D` to open diff panel for the currently selected PR.

### Keyboard Navigation Additions

Currently, the only keyboard shortcut is the global hotkey (`Cmd+Shift+Option+P` to toggle the panel). Proposed additions:

| Shortcut | Action |
|---|---|
| `Cmd+R` | Refresh PR list |
| `Cmd+F` | Focus search bar |
| `Cmd+D` | Open diff panel for selected PR |
| `Cmd+1-5` | Switch between filter tabs |
| `Up/Down` | Navigate PR list |
| `Enter` | Open selected PR detail |
| `Esc` | Go back / close panel |
| `Cmd+,` | Open Settings |

---

### Information Architecture

**Filter Model Unification (P1-6):**

The current dual model creates cognitive friction:

```
DashboardState (computed, never exposed):    PRFilter (exposed, used):
  needsAction                                  All
  readyToShip                                  My PRs
  waitingOnOthers                              Review Requested
                                               Mentioned
                                               Blocked by Me
```

**Proposed Unified Filter Model:**

```swift
enum PRFilter: String, CaseIterable {
    // Triage categories (primary)
    case all = "All"
    case needsAction = "Needs Action"
    case readyToShip = "Ready to Ship"
    case waitingOnOthers = "Waiting"

    // Perspective filters (secondary, collapsible)
    case myPRs = "My PRs"
    case reviewRequested = "Review Requested"
    case mentioned = "Mentioned"
    case blockedByMe = "Blocked by Me"
}
```

The filter bar could show triage categories as the primary row and perspective filters as a secondary expandable row, or use a segmented control for triage with a dropdown for perspective.

**Urgency Score Transparency (P2):**

The urgency score is computed on `PullRequest` but the algorithm is opaque to users. The `UrgencyBadge` shows the age but not why a PR is urgent.

**Recommendation:** Add a tooltip to the urgency badge that breaks down the score: "Urgent: 3 days old, changes requested, CI failing, has conflicts." This provides transparency without adding visual clutter.

**Progressive Disclosure:**

The current dashboard stacks all filter layers vertically: FilterBar, SearchBar, LabelFilterView, AuthorFilterView. This consumes significant vertical space before any PR content appears.

**Recommendation:** Collapse label and author filters by default (already implemented via `isExpanded` state). Add a combined filter count badge next to the search bar showing total active filters.

---

### Task Flow Optimization

**Wiring QuickActionsView (P0-1):**

Insert `QuickActionsView` into `PRDetailView` after the detail header, gated by PR state:

```swift
// In PRDetailView, after detailHeader and before synopsisSection:
if pr.state == .open && !pr.isDraft {
    QuickActionsView(
        pr: pr,
        onApprove: { Task { await approveCurrentPR() } },
        onMerge: { method in Task { await mergeCurrentPR(method: method) } },
        onRequestChanges: { comment in Task { await requestChanges(comment: comment) } }
    )
    .padding(.horizontal, 12)
    GlowDivider()
}
```

**Comment Initiation in Diffs:**

Currently, users can only reply to existing review threads in the diff view. There is no way to start a new review comment on a specific line. This is a significant gap for code review workflows.

**Recommendation:** Add a "+" button on each diff line gutter that opens a `CommentComposer` anchored to that line. This requires a new GraphQL mutation (`addPullRequestReviewComment`).

**Mention Tracking Fix (P0-3):**

1. Add a lightweight mention check to the dashboard refresh cycle. When `refresh()` completes, call `mentionTracker.checkForMentions(prs: allPRs, currentUser: currentUser)`.
2. Since `pr.detail` is nil at this point, modify `checkForMentions` to also check `pr.reviewRequests` (already loaded) as a proxy.
3. Add a `@mentions` indicator in the PR row for PRs where the user is mentioned.

---

## Brand Strategy

### Name Resolution

**Recommendation:** Standardize on **P-Arr** as the canonical display name everywhere.

| Context | Current | Proposed |
|---|---|---|
| Header bar | "PR WIDGET" | "P-ARR" |
| Menu bar tooltip | "PR Widget" | "P-Arr" |
| Settings window title | "P-Arr Settings" | "P-Arr Settings" (correct) |
| Quit menu item | "Quit P-Arr" | "Quit P-Arr" (correct) |
| About section | "P-Arr -- Catalyst DevSpace" | "P-Arr -- Catalyst DevSpace" (correct) |
| Package name | "PArr" | "PArr" (acceptable for code identifiers) |
| Source directory | "PRWidget/" | "PRWidget/" (acceptable; avoid renaming to prevent git churn) |
| Homebrew cask | "p-arr" | "p-arr" (correct) |
| NSLog prefix | "[PArr]" | "[PArr]" (acceptable for logs) |

**Migration Checklist:**
- [ ] Change `DashboardHeaderBar.swift` line 28: `"PR WIDGET"` to `"P-ARR"`
- [ ] Change `AppDelegate.swift` line 85: `accessibilityDescription: "PR Widget"` to `"P-Arr"`
- [ ] Verify all user-facing strings use "P-Arr" (hyphenated, capitalized)
- [ ] Accept "PArr" for code identifiers and "p-arr" for Homebrew (standard conventions)

---

### Brand Expression

**Visual Identity Recommendations:**

The cybersynthpunk aesthetic is the product's strongest differentiator. Key visual signatures to preserve:
- Neon cyan (#00fcd6) as primary accent
- Dark background (#0a0a0f) with glass card layering
- Monospaced typography throughout
- Glow effects on interactive elements
- Gradient accent stripes on PR rows

**Custom Icon Direction (P3-21):**

The current menu bar icon uses SF Symbol `arrow.trianglehead.pull`, which is the generic git PR icon used by every GitHub client. A custom icon would strengthen brand recognition.

**Recommendation:** Design a custom menu bar icon that combines the PR merge arrow motif with the cyberpunk aesthetic. Options:
- Stylized "P" with a merge arrow integrated into the letterform
- The existing merge arrow with a neon glow treatment (template image with custom rendering)
- A pirate-themed "arr" motif (skull-and-crossbones merge arrow) if the pirate naming theme is to be embraced

**Tagline Suggestions:**
- "Your PRs, at a glance." (functional)
- "Triage at light speed." (aspirational, matches cyberpunk theme)
- "Neon-powered PR triage." (brand-forward)

---

## Implementation Roadmap

### Phase 1: Critical Fixes (1-2 weeks)

**Objective:** Ship all P0 fixes and eliminate trust-eroding defects.

| # | Task | Files | Effort |
|---|---|---|---|
| 1.1 | Wire `QuickActionsView` into `PRDetailView` | `PRDetailView.swift`, `DashboardStore.swift` | 4h |
| 1.2 | Add merge confirmation dialog | `MergeOptionsView.swift` (new `ConfirmationDialog`) | 4h |
| 1.3 | Fix `MentionTracker.markAllMentionsRead` no-op | `MentionTracker.swift` line 63 | 1h |
| 1.4 | Fix `MentionTracker.markAsRead` dead `currentUser` | `MentionTracker.swift` line 48 | 30m |
| 1.5 | Fix mention detection to work without preloaded detail | `MentionTracker.swift` lines 29-30, `DashboardStore.swift` | 4h |
| 1.6 | Fix comment data loss on failure | `CommentComposer.swift` lines 30-38 | 1h |
| 1.7 | Fix multi-monitor positioning | `WindowManager.swift` line 129, `AppDelegate.swift` line 273 | 30m |
| 1.8 | Unify display name to "P-ARR" in header | `DashboardHeaderBar.swift` line 28, `AppDelegate.swift` line 85 | 30m |

**Total estimated effort: 15-16 hours**

---

### Phase 2: Design System Foundation (2-3 weeks)

**Objective:** Establish tokenized typography, spacing, and border systems. Extract shared components.

| # | Task | Files | Effort |
|---|---|---|---|
| 2.1 | Define type scale tokens in `CatalystTheme.swift` | `CatalystTheme.swift` | 2h |
| 2.2 | Replace 147 raw font calls with token references | 22 view files | 8h |
| 2.3 | Wire UIScale to new font tokens (resolves P0-4) | `ScaledFont.swift`, type scale tokens | 2h |
| 2.4 | Define spacing tokens | `CatalystTheme.swift` | 1h |
| 2.5 | Define border width tokens | `CatalystTheme.swift` | 30m |
| 2.6 | Extract `ToggleChip` (unified from Label/Author) | New `ToggleChip.swift`, update `LabelFilterView.swift`, `AuthorFilterView.swift` | 3h |
| 2.7 | Move `FlowLayout` to catalyst-lib | `LabelFilterView.swift` -> `catalyst-lib/Sources/CatalystSwift/Layout/FlowLayout.swift` | 1h |
| 2.8 | Merge `PRRowView` and `PRRowContent` | `PRRowView.swift`, `DashboardView.swift` | 3h |
| 2.9 | Extract `SectionHeader` component | New shared component, update ~8 files | 3h |
| 2.10 | Extract `EmptyState` component | New shared component, update `DashboardView.swift`, `DiffPanelView.swift` | 2h |
| 2.11 | Extract shared `relativeTime()` utility | `InlineCommentThread.swift`, `ActivityFeed.swift` -> shared extension | 1h |
| 2.12 | Resolve yellow overload: introduce `Catalyst.pinned` | `CatalystTheme+PR.swift`, all pin-related views | 2h |

**Total estimated effort: 28-30 hours**

---

### Phase 3: UX Enhancement (3-4 weeks)

**Objective:** Rearchitect filter system, add accessibility, improve platform integration.

| # | Task | Files | Effort |
|---|---|---|---|
| 3.1 | Unify PRFilter + DashboardState triage categories | `PRFilter.swift`, `DashboardState.swift`, `FilterBar.swift`, `DashboardStore.swift` | 6h |
| 3.2 | Rename "Ready for QA" to "Ready to Ship" | `DashboardHeaderBar.swift` | 30m |
| 3.3 | Fix simultaneous NavigationLink + diff panel click | `DashboardView.swift` lines 196-202, 250-257 | 2h |
| 3.4 | Add Reduce Motion support | `WindowManager.swift`, all `hoverGlow` usages, shimmer modifier | 4h |
| 3.5 | Add Reduce Transparency support | Glass card modifier, `Catalyst.glass` | 2h |
| 3.6 | Add Differentiate Without Color support | `StatusBadge.swift`, `UrgencyBadge.swift`, review state indicators | 3h |
| 3.7 | Add clipboard confirmation toast | Context menu copy actions across `PRRowView.swift`, `PRRowContent` | 3h |
| 3.8 | Add keyboard shortcuts (Cmd+R, Cmd+F, arrows) | `DashboardView.swift`, `AppDelegate.swift` | 4h |
| 3.9 | Unify tooltip systems (`.catalystTooltip` vs `.help`) | `DashboardHeaderBar.swift`, `ReviewAvatars.swift`, `LabelPills.swift` | 2h |
| 3.10 | Add drag-to-reorder visual affordance | Repo group headers in `DashboardView.swift` | 2h |
| 3.11 | Add urgency score tooltip breakdown | `UrgencyBadge.swift` | 2h |
| 3.12 | Add UserNotifications for mention alerts | New `NotificationManager.swift` | 4h |

**Total estimated effort: 34-36 hours**

---

### Phase 4: Brand and Polish (Ongoing)

**Objective:** Complete brand unification, add platform polish, strengthen competitive position.

| # | Task | Effort |
|---|---|---|
| 4.1 | Design and implement custom menu bar icon | 4-8h |
| 4.2 | Add Launch-at-Login support (via SMAppService) | 2h |
| 4.3 | Theme Settings views to match cyberpunk aesthetic | 4h |
| 4.4 | Build component catalog (SwiftUI previews) | 8h |
| 4.5 | Add About section with version, credits, links | 2h |
| 4.6 | Evaluate light mode support or document dark-mode-only as intentional | 2h |
| 4.7 | Add new-comment-on-line capability in diff viewer | 8h |
| 4.8 | Polish diff viewer with syntax highlighting | 8h |

---

## Appendix

### A. Full Score Breakdown by Agent

| Agent | Domain | Score | Weight | Weighted |
|---|---|---|---|---|
| Brand | Brand Coherence | 5/10 | 1.0 | 5.0 |
| Visual | Visual Clarity | 9/10 | 1.0 | 9.0 |
| Visual | Visual Hierarchy | 9/10 | 1.0 | 9.0 |
| Visual | Layout Quality | 8/10 | 0.8 | 6.4 |
| Color | Color System | 8/10 | 1.0 | 8.0 |
| Typography | Typography | 7/10 | 0.8 | 5.6 |
| Visual | Aesthetic Coherence | 9/10 | 0.8 | 7.2 |
| Component | Token Completeness | 4/10 | 1.0 | 4.0 |
| Component | Component Maturity | 5/10 | 1.0 | 5.0 |
| Component | Design System Consistency | 7/10 | 0.8 | 5.6 |
| IA | IA Quality | 7/10 | 0.8 | 5.6 |
| IA | Navigation | 7/10 | 0.8 | 5.6 |
| IA | Mental Model | 7/10 | 0.8 | 5.6 |
| UX Flow | Task Completion | 5/10 | 1.2 | 6.0 |
| UX Flow | Microinteractions | 7/10 | 0.6 | 4.2 |
| UX Flow | Feedback Completeness | 5/10 | 1.0 | 5.0 |
| UX Flow | Discoverability | 4/10 | 1.0 | 4.0 |
| UX Flow | Cognitive Load | 6/10 | 0.8 | 4.8 |
| UX Flow | Learnability | 5/10 | 0.8 | 4.0 |
| Platform | macOS Compliance | 7/10 | 0.8 | 5.6 |
| Platform | Accessibility | 3/10 | 1.2 | 3.6 |
| Platform | Platform Integration | 3/10 | 1.0 | 3.0 |
| Brand | UX Differentiation | 9/10 | 0.6 | 5.4 |
| Brand | Competitive Moat | 5/10 | 0.8 | 4.0 |

### B. Files Requiring Changes (Grouped by Priority)

**Phase 1 (P0/Critical):**
- `PRWidget/Views/Detail/PRDetailView.swift`
- `PRWidget/Views/Actions/MergeOptionsView.swift`
- `PRWidget/Services/MentionTracker.swift`
- `PRWidget/Views/Diff/CommentComposer.swift`
- `PRWidget/Window/WindowManager.swift`
- `PRWidget/App/AppDelegate.swift`
- `PRWidget/Views/Dashboard/DashboardHeaderBar.swift`
- `PRWidget/Store/DashboardStore.swift`

**Phase 2 (Design System):**
- `catalyst-lib/Sources/CatalystSwift/Theme/CatalystTheme.swift`
- `PRWidget/Extensions/CatalystTheme+PR.swift`
- All 22 view files with raw `.font(.system(size:))` calls (see Typography section)
- `PRWidget/Views/Dashboard/LabelFilterView.swift` (FlowLayout extraction, ToggleChip unification)
- `PRWidget/Views/Dashboard/AuthorFilterView.swift` (ToggleChip unification)
- `PRWidget/Views/Dashboard/PRRowView.swift` (merge with PRRowContent)
- `PRWidget/Views/Dashboard/DashboardView.swift` (PRRowContent removal, EmptyState extraction)
- `PRWidget/Views/Diff/InlineCommentThread.swift` (relativeTime extraction)
- `PRWidget/Views/Detail/ActivityFeed.swift` (relativeTime extraction)

**Phase 3 (UX Enhancement):**
- `PRWidget/Models/PRFilter.swift`
- `PRWidget/Models/DashboardState.swift`
- `PRWidget/Views/Dashboard/FilterBar.swift`
- `PRWidget/Views/Components/UrgencyBadge.swift`
- `PRWidget/Views/Components/StatusBadge.swift`
- `PRWidget/Views/Components/ReviewAvatars.swift`
- `PRWidget/Views/Dashboard/SearchBar.swift`
- `PRWidget/Views/Diff/DiffPanelView.swift`

**Phase 4 (Polish):**
- `PRWidget/Views/Settings/SettingsView.swift`
- `PRWidget/Views/Settings/GeneralSettingsView.swift`
- `PRWidget/Views/Settings/AISettingsView.swift`
- `PRWidget/Views/Settings/PromptSettingsView.swift`
- `PRWidget/Views/Settings/AccountSetupView.swift`
- `PRWidget/Views/Settings/AccountsSettingsView.swift`

### C. Systemic Patterns Summary

| Pattern | Occurrences | Root Cause | Remedy |
|---|---|---|---|
| Built-but-not-connected | 3 (QuickActions, UIScale, MentionTracker) | Feature branches merged without integration testing | Add integration tests; PR checklist requiring "feature is reachable from UI" |
| Duplicated-instead-of-abstracted | 5 (ToggleChip, PRRow, FlowLayout, relativeTime, ChipState) | Speed of development over architecture | Extract during Phase 2; enforce via code review |
| Theme at tokens, chaos at consumption | 147 raw font calls, ad-hoc spacing | No enforcement mechanism | Type/spacing tokens with linter rule or SwiftLint custom rule |
| Accessibility as afterthought | 0 Reduce Motion checks, 0 Dynamic Type | Not in scope during initial development | Phase 3 remediation; add to Definition of Done |
| Naming/conceptual inconsistency | 4 name variants, dual filter models | Incomplete rename migration; organic growth | Phase 1 name fix; Phase 3 filter unification |

---

*Report generated 2026-03-15. Next review recommended after Phase 2 completion.*
