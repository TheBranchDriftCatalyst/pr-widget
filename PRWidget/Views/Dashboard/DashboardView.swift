import SwiftUI
import CatalystSwift

struct DashboardView: View {
    @Environment(DashboardStore.self) var store
    @Environment(AccountManager.self) var accountManager
    @FocusState private var isSearchFocused: Bool

    var onOpenSettings: () -> Void = {}
    var onTogglePin: () -> Void = {}

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            VStack(spacing: 0) {
                DashboardHeaderBar(
                    lastRefreshed: store.state.lastRefreshed,
                    isLoading: store.state.isLoading,
                    isPinned: store.isPinned,
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
                    FilterBar(activeFilter: $store.activeFilter)
                    GlowDivider()
                    SearchBar(text: $store.searchQuery, isFocused: $isSearchFocused)
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

                Button("") { isSearchFocused = true }
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

    private var prListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {

                if let error = store.state.error {
                    ErrorBannerView(message: error)
                }

                // Pinned section
                let pinned = store.pinnedPRs
                if !pinned.isEmpty {
                    PinnedSection(prs: pinned, store: store)
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
                            store: store,
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
                .font(.caption)
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

// MARK: - Pinned Section

private struct PinnedSection: View {
    let prs: [PullRequest]
    let store: DashboardStore

    var body: some View {
        Section {
            ForEach(prs) { pr in
                NavigationLink(value: pr) {
                    PRRowContent(pr: pr, store: store)
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

                Text("PINNED")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .tracking(1)
                    .foregroundStyle(Catalyst.foreground)

                Text("\(prs.count)")
                    .scaledFont(size: 10, weight: .medium, design: .monospaced)
                    .foregroundStyle(Catalyst.yellow)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Catalyst.yellow.opacity(0.15), in: Capsule())

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
    let store: DashboardStore
    let onToggle: () -> Void
    let onCmdToggle: () -> Void
    var onDrop: (String) -> Void = { _ in }

    var body: some View {
        Section {
            if !isCollapsed {
                ForEach(prs) { pr in
                    NavigationLink(value: pr) {
                        PRRowContent(pr: pr, store: store)
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

            Circle()
                .fill(Catalyst.cyan)
                .frame(width: 6, height: 6)
                .shadow(color: Catalyst.cyan.opacity(0.5), radius: 3)

            Text(repoName.uppercased())
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.foreground)
                .lineLimit(1)

            Text("\(prs.count)")
                .scaledFont(size: 10, weight: .medium, design: .monospaced)
                .foregroundStyle(Catalyst.cyan)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Catalyst.cyan.opacity(0.15), in: Capsule())

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
    let store: DashboardStore
    @Environment(AccountManager.self) private var accountManager

    var body: some View {
        HStack(spacing: 0) {
            GradientAccentStripe(color: accentColor(for: pr))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    if pr.isDraft {
                        Image(systemName: "doc")
                            .font(.caption)
                            .foregroundStyle(Catalyst.subtle)
                    }

                    if store.isPinned(pr.id) {
                        Image(systemName: "pin.fill")
                            .scaledFont(size: 9)
                            .foregroundStyle(Catalyst.yellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pr.title)
                            .scaledFont(size: 14)
                            .fontWeight(.medium)
                            .foregroundStyle(Catalyst.foreground)
                            .lineLimit(2)

                        Text("\(pr.repository.nameWithOwner) #\(pr.number)")
                            .scaledFont(size: 11)
                            .fontDesign(.monospaced)
                            .foregroundStyle(Catalyst.muted)
                    }

                    Spacer()

                    UrgencyBadge(ageText: pr.ageText, urgencyScore: pr.urgencyScore)
                }

                HStack(spacing: 8) {
                    StatusBadge(status: pr.statusCheckRollup)
                    ReviewAvatars(reviews: pr.reviews, reviewRequests: pr.reviewRequests)

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
                    .scaledFont(size: 11)
                    .fontDesign(.monospaced)
                }

                if !pr.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(pr.labels.prefix(5)) { label in
                            LabelPill(label: label)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier(AccessibilityID.prRow(id: pr.id))
        .hoverGlow(accentColor(for: pr))
        .contextMenu {
            Button(store.isPinned(pr.id) ? "Unpin" : "Pin") {
                store.togglePin(pr.id)
            }
            Divider()
            Button("Open in Browser") {
                NSWorkspace.shared.open(pr.url)
            }
            Button("Copy URL") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.url.absoluteString, forType: .string)
            }
            Divider()
            Button("Copy Branch Name") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.headRefName, forType: .string)
            }
            Divider()
            LabelContextMenu(pr: pr, store: store, accountManager: accountManager)
        }
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
