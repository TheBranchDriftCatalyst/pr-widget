import SwiftUI
import CatalystSwift

struct DashboardView: View {
    @Environment(DashboardStore.self) var store
    @Environment(AccountManager.self) var accountManager
    @Environment(WindowManager.self) var windowManager
    @State private var requestSearchFocus = false

    var onOpenSettings: () -> Void = {}
    var onTogglePin: () -> Void = {}

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 0) {
                DashboardHeaderBar(
                    lastRefreshed: store.state.lastRefreshed,
                    isLoading: store.state.isLoading,
                    isPinned: windowManager.isPinned,
                    blockedByMe: store.state.blockedByMeCount,
                    ownedByMe: store.state.ownedByMeCount,
                    readyToShip: store.state.readyToShipCount,
                    onRefresh: { Task { await store.refresh() } },
                    onTogglePin: onTogglePin,
                    onOpenSettings: onOpenSettings
                )
                GlowDivider()

                if !accountManager.hasAccounts {
                    noAccountView
                        .accessibilityIdentifier(AccessibilityID.noAccountView)
                } else if store.state.isEmpty && !store.state.isLoading {
                    emptyStateView
                        .accessibilityIdentifier(AccessibilityID.emptyStateView)
                } else {
                    DashboardMainContent(requestSearchFocus: $requestSearchFocus)
                }
            }
            .accessibilityIdentifier(AccessibilityID.dashboardView)
            .frame(minWidth: 380, maxWidth: 600, minHeight: 300, maxHeight: 900)
            .background(Catalyst.background)
            .navigationDestination(for: PullRequest.self) { pr in
                PRDetailView(pr: pr)
                    .environment(store)
                    .environment(accountManager)
            }
        }
        .background {
            // Keyboard shortcuts via hidden buttons
            Group {
                Button("") { Task { await store.refresh() } }
                    .keyboardShortcut("r", modifiers: .command)

                Button("") { requestSearchFocus = true }
                    .keyboardShortcut("f", modifiers: .command)

                Button("") { onOpenSettings() }
                    .keyboardShortcut(",", modifiers: .command)

                // Cmd+1-4 for triage filter tabs
                ForEach(Array(PRFilter.triageFilters.enumerated()), id: \.offset) { index, filter in
                    Button("") { store.activeFilter = filter }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    private var noAccountView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.badge.key")
                .scaledFont(size: 40)
                .foregroundStyle(Catalyst.magenta)
            Text("NO ACCOUNTS")
                .scaledFont(size: 14, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.foreground)
            Text("Add a GitHub account to get started.")
                .scaledFont(size: 11)
                .foregroundStyle(Catalyst.muted)
                .multilineTextAlignment(.center)
            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
                .tint(Catalyst.cyan)
                .foregroundStyle(Catalyst.background)
                .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var emptyStateView: some View {
        EmptyState(
            icon: "checkmark.circle",
            title: "INBOX ZERO",
            subtitle: "No open pull requests need your attention.",
            iconColor: Catalyst.cyan
        )
        .padding()
    }
}

// MARK: - Dashboard Main Content (extracted from DashboardView.body)

private struct DashboardMainContent: View {
    @Environment(DashboardStore.self) var store
    @Binding var requestSearchFocus: Bool

    var body: some View {
        @Bindable var store = store
        FilterBar(activeFilter: $store.activeFilter)
        GlowDivider()
        SearchBar(text: $store.searchQuery, requestFocus: $requestSearchFocus)
        GlowDivider()
        LabelFilterView(
            availableLabels: store.availableLabels,
            selectedLabels: $store.selectedLabels,
            excludedLabels: $store.excludedLabels
        )
        GlowDivider()
        AuthorFilterView(
            availableAuthors: store.availableAuthors,
            selectedAuthors: $store.selectedAuthors,
            excludedAuthors: $store.excludedAuthors
        )
        GlowDivider()
        prListContent
    }

    private var prListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {

                if let error = store.state.error {
                    ErrorBannerView(message: error)
                }

                // Pinned section
                let pinned = store.pinnedPRs
                if !pinned.isEmpty {
                    PinnedSection(
                        prs: pinned,
                        pinnedIDs: store.pinnedPRIDs,
                        onTogglePin: { store.togglePin($0) }
                    )
                }

                // Repo groups
                let groups = store.groupedByRepo
                if groups.isEmpty && pinned.isEmpty && !store.state.isLoading {
                    noMatchView
                } else {
                    ForEach(Array(groups.enumerated()), id: \.element.repoName) { index, group in
                        RepoGroupSection(
                            repoName: group.repoName,
                            prs: group.prs,
                            isCollapsed: store.collapsedRepos.contains(group.repoName),
                            pinnedIDs: store.pinnedPRIDs,
                            onTogglePin: { store.togglePin($0) },
                            onToggle: {
                                if store.collapsedRepos.contains(group.repoName) {
                                    store.collapsedRepos.remove(group.repoName)
                                } else {
                                    store.collapsedRepos.insert(group.repoName)
                                }
                            },
                            onCmdToggle: {
                                if store.allCollapsed {
                                    store.expandAll()
                                } else {
                                    store.collapseAll()
                                }
                            },
                            onDrop: { fromRepo in
                                guard fromRepo != group.repoName else { return }
                                var order = groups.map(\.repoName)
                                guard let fromIdx = order.firstIndex(of: fromRepo) else { return }
                                order.remove(at: fromIdx)
                                let toIdx = min(index, order.count)
                                order.insert(fromRepo, at: toIdx)
                                store.repoOrder = order
                            }
                        )
                    }
                }
            }
            .catalystScrollbar()
        }
        .accessibilityIdentifier(AccessibilityID.prList)
    }

    private var noMatchView: some View {
        EmptyState(icon: "magnifyingglass", title: "NO MATCHES")
            .padding()
            .accessibilityIdentifier(AccessibilityID.noMatchView)
    }
}

// MARK: - Pinned Section

private struct PinnedSection: View {
    let prs: [PullRequest]
    let pinnedIDs: Set<String>
    let onTogglePin: (String) -> Void

    var body: some View {
        Section {
            ForEach(prs) { pr in
                NavigationLink(value: pr) {
                    PRRowContent(
                        pr: pr,
                        isPinned: pinnedIDs.contains(pr.id),
                        onTogglePin: { onTogglePin(pr.id) }
                    )
                }
                .buttonStyle(.plain)
                if pr.id != prs.last?.id {
                    GlowDivider()
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .scaledFont(size: 9)
                    .foregroundStyle(Catalyst.yellow)
                    .shadow(color: Catalyst.yellow.opacity(0.5), radius: 3)

                SectionHeader(title: "PINNED", accentColor: Catalyst.foreground)

                CountBadge(count: prs.count, color: Catalyst.yellow)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassCard()
        }
    }
}

// MARK: - Repo Group Section

private struct RepoGroupSection: View {
    let repoName: String
    let prs: [PullRequest]
    let isCollapsed: Bool
    let pinnedIDs: Set<String>
    let onTogglePin: (String) -> Void
    let onToggle: () -> Void
    let onCmdToggle: () -> Void
    var onDrop: (String) -> Void = { _ in }

    var body: some View {
        Section {
            if !isCollapsed {
                ForEach(prs) { pr in
                    NavigationLink(value: pr) {
                        PRRowContent(
                            pr: pr,
                            isPinned: pinnedIDs.contains(pr.id),
                            onTogglePin: { onTogglePin(pr.id) }
                        )
                    }
                    .buttonStyle(.plain)
                    if pr.id != prs.last?.id {
                        GlowDivider()
                    }
                }
            }
        } header: {
            repoHeader
        }
    }

    private var repoHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .scaledFont(size: 9, weight: .bold)
                .foregroundStyle(Catalyst.subtle)
                .frame(width: 12)
                .animation(.easeInOut(duration: 0.2), value: isCollapsed)

            NeonDot(color: Catalyst.cyan)

            Text(repoName.uppercased())
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.foreground)
                .lineLimit(1)

            CountBadge(count: prs.count, color: Catalyst.cyan)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassCard()
        .onTapGesture {
            onToggle()
        }
        .simultaneousGesture(
            TapGesture().modifiers(.command).onEnded {
                onCmdToggle()
            }
        )
        .draggable(repoName)
        .dropDestination(for: String.self) { items, _ in
            guard let draggedRepo = items.first else { return false }
            onDrop(draggedRepo)
            return true
        }
    }
}

// MARK: - PR Row Content (for NavigationLink)

struct PRRowContent: View {
    let pr: PullRequest
    let isPinned: Bool
    let onTogglePin: () -> Void
    @Environment(AccountManager.self) private var accountManager
    @Environment(DashboardStore.self) private var store

    private var isOwnedByMe: Bool {
        pr.author.login == store.state.currentUser
    }

    var body: some View {
        HStack(spacing: 0) {
            GradientAccentStripe(color: accentColor(for: pr))

            VStack(alignment: .leading, spacing: 4) {
                // Line 1: Title row with CI status + comment count
                HStack(alignment: .top, spacing: 6) {
                    if pr.isDraft {
                        Image(systemName: "doc")
                            .scaledFont(size: 11)
                            .foregroundStyle(Catalyst.subtle)
                    }

                    if isPinned {
                        Image(systemName: "pin.fill")
                            .scaledFont(size: 9)
                            .foregroundStyle(Catalyst.yellow)
                    }

                    if isOwnedByMe {
                        Text("👑")
                            .scaledFont(size: 10)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(pr.repository.nameWithOwner)
                                .scaledFont(size: 11, weight: .semibold)
                                .foregroundStyle(Catalyst.muted)

                            Text(pr.title)
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundStyle(Catalyst.foreground)
                                .lineLimit(2)

                            StatusBadge(status: pr.statusCheckRollup)

                            if !pr.labels.isEmpty {
                                ForEach(pr.labels.prefix(5)) { label in
                                    LabelPill(label: label)
                                }
                            }
                        }

                        // Line 2: Metadata line matching GitHub format
                        HStack(spacing: 4) {
                            Text("#\(pr.number)")
                                .foregroundStyle(Catalyst.muted)

                            Text("opened \(pr.createdAt, style: .relative) ago")
                                .foregroundStyle(Catalyst.muted)

                            Text("by \(pr.author.login)")
                                .foregroundStyle(Catalyst.muted)

                            if pr.isDraft {
                                Text("•")
                                    .foregroundStyle(Catalyst.subtle)
                                Text("Draft")
                                    .foregroundStyle(Catalyst.subtle)
                            } else if pr.reviewDecision == .reviewRequired {
                                Text("•")
                                    .foregroundStyle(Catalyst.subtle)
                                Text("Review required")
                                    .foregroundStyle(Catalyst.subtle)
                            }

                            if let progress = pr.taskProgress {
                                TaskProgressView(progress: progress)
                            }
                        }
                        .scaledFont(size: 11)
                    }

                    Spacer()

                    // Comment count
                    if pr.commentCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "text.bubble")
                            Text("\(pr.commentCount)")
                        }
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.muted)
                    }
                }

                // Line 3: Review status row
                HStack(spacing: 8) {
                    ReviewAvatars(reviews: pr.reviews, reviewRequests: pr.reviewRequests)
                    myReviewBadge

                    if pr.mergeable == .conflicting {
                        Label("Conflicts", systemImage: "exclamationmark.triangle.fill")
                            .scaledFont(size: 11)
                            .foregroundStyle(Catalyst.warning)
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Text("+\(pr.additions)")
                            .foregroundStyle(Catalyst.cyan)
                        Text("-\(pr.deletions)")
                            .foregroundStyle(Catalyst.red)
                    }
                    .scaledFont(size: 11, design: .monospaced)

                    UrgencyBadge(ageText: pr.ageText, urgencyScore: pr.urgencyScore)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier(AccessibilityID.prRow(id: pr.id))
        .hoverGlow(accentColor(for: pr))
        .contextMenu {
            Button(isPinned ? "Unpin" : "Pin") {
                onTogglePin()
            }
            Divider()
            Button("Open in Browser") {
                NSWorkspace.shared.open(pr.url)
            }
            Button("Open Repo") {
                NSWorkspace.shared.open(pr.repository.url)
            }
            if let tasksURL = URL(string: "\(pr.url.absoluteString)/checks") {
                Button("Open Checks") {
                    NSWorkspace.shared.open(tasksURL)
                }
            }
            if let projectsURL = URL(string: "\(pr.repository.url.absoluteString)/projects") {
                Button("Open Project Board") {
                    NSWorkspace.shared.open(projectsURL)
                }
            }
            Divider()
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.url.absoluteString, forType: .string)
            }
            Button("Copy Branch Name") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.headRefName, forType: .string)
            }
            Divider()
            LabelContextMenu(pr: pr, store: store, accountManager: accountManager)
        }
    }

    /// Shows the current user's review state on this PR.
    @ViewBuilder
    private var myReviewBadge: some View {
        let currentUser = store.state.currentUser
        let isAuthor = pr.author.login == currentUser
        let myReview = pr.reviews.last { $0.author.login == currentUser }
        let reviewRequested = pr.reviewRequests.contains { $0.login == currentUser }

        if isAuthor {
            // Show review decision for your own PRs
            switch pr.reviewDecision {
            case .approved:
                reviewPill("APPROVED", icon: "checkmark", color: Catalyst.approved)
            case .changesRequested:
                reviewPill("CHANGES", icon: "xmark", color: Catalyst.changesRequested)
            case .reviewRequired:
                reviewPill("PENDING", icon: "clock", color: Catalyst.pendingReview)
            case nil:
                EmptyView()
            }
        } else if let myReview {
            switch myReview.state {
            case .approved:
                reviewPill("YOU APPROVED", icon: "checkmark", color: Catalyst.approved)
            case .changesRequested:
                reviewPill("YOU BLOCKED", icon: "xmark", color: Catalyst.changesRequested)
            case .commented:
                reviewPill("COMMENTED", icon: "text.bubble", color: Catalyst.commented)
            case .dismissed, .pending:
                if reviewRequested {
                    reviewPill("REVIEW", icon: "eye", color: Catalyst.yellow)
                }
            }
        } else if reviewRequested {
            reviewPill("REVIEW", icon: "eye", color: Catalyst.yellow)
        }
    }

    private func reviewPill(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .scaledFont(size: 9, weight: .bold, design: .monospaced)
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
    }

    private func accentColor(for pr: PullRequest) -> Color {
        if pr.reviewDecision == .approved && pr.statusCheckRollup == .success && pr.mergeable == .mergeable && !pr.isDraft {
            return Catalyst.readyToShip
        }
        if pr.reviewDecision == .changesRequested || pr.statusCheckRollup == .failure || pr.mergeable == .conflicting {
            return Catalyst.needsAction
        }
        return Catalyst.waiting
    }
}

// MARK: - Task Progress View

struct TaskProgressView: View {
    let progress: TaskProgress

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .trim(from: 0, to: progress.total > 0 ? CGFloat(progress.completed) / CGFloat(progress.total) : 0)
                .stroke(Catalyst.muted, lineWidth: 1.5)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(-90))
                .overlay(
                    Circle()
                        .stroke(Catalyst.subtle.opacity(0.3), lineWidth: 1.5)
                )

            Text("\(progress.completed) of \(progress.total) tasks")
                .foregroundStyle(Catalyst.muted)
        }
        .scaledFont(size: 11)
    }
}
