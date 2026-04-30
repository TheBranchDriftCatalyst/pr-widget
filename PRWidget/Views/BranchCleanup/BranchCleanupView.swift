import SwiftUI
import CatalystSwift
import TelemetryDeck

struct BranchCleanupView: View {
    @Environment(BranchCleanupStore.self) var store
    @Environment(AccountManager.self) var accountManager

    @State private var showDeleteConfirmation = false
    @State private var sortOrder = [KeyPathComparator(\BranchInfo.lastActivity, order: .reverse)]

    private var sortedBranches: [BranchInfo] {
        store.filteredBranches.sorted(using: sortOrder)
    }

    var body: some View {
        @Bindable var store = store

        VStack(spacing: 0) {
            BranchCleanupHeaderBar(
                branchCount: store.branches.count,
                workspaceRoot: store.workspaceRoot,
                isLoading: store.isLoading,
                onRefresh: { Task { await store.refreshAllBranches() } },
                onPickFolder: pickWorkspaceFolder
            )

            GlowDivider()

            BranchCleanupFilterBar(
                searchQuery: $store.searchQuery,
                hasBranches: !store.filteredBranches.isEmpty,
                selectedCount: store.selectedBranchIDs.count,
                onSelectAll: store.selectAllVisible,
                onDeselectAll: store.deselectAll,
                onDeleteSelected: { showDeleteConfirmation = true }
            )

            // Chip-based include/exclude filters
            CollapsibleFilterSection(
                icon: "person",
                title: "COMMITTERS",
                items: store.availableCommitters,
                selected: $store.selectedCommitters,
                excluded: $store.excludedCommitters
            )

            CollapsibleFilterSection(
                icon: "folder",
                title: "REPOS",
                items: store.availableRepos,
                selected: $store.selectedRepos,
                excluded: $store.excludedRepos
            )

            GlowDivider()

            if store.workspaceRoot.isEmpty {
                EmptyState(
                    icon: "folder",
                    title: "NO WORKSPACE SET",
                    subtitle: "Select a workspace folder containing your git repos."
                )
            } else if store.isLoading && store.filteredBranches.isEmpty {
                Spacer()
                ProgressView()
                    .controlSize(.regular)
                    .tint(Catalyst.cyan)
                Text("Scanning workspace...")
                    .scaledFont(size: 11, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
                    .padding(.top, 6)
                Spacer()
            } else if store.filteredBranches.isEmpty {
                EmptyState(
                    icon: "leaf",
                    title: "NO BRANCHES FOUND",
                    subtitle: store.branches.isEmpty
                        ? "No git repos found in workspace."
                        : "Adjust your filters to see branches."
                )
            } else {
                Table(of: BranchInfo.self, selection: $store.selectedBranchIDs, sortOrder: $sortOrder) {
                    TableColumn("Branch", value: \.name) { branch in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(branch.name)
                                .scaledFont(size: 12, weight: .medium, design: .monospaced)
                                .foregroundStyle(branch.location == .local ? Catalyst.yellow : Catalyst.foreground)
                                .lineLimit(1)
                            Text(branch.repoName)
                                .scaledFont(size: 9, design: .monospaced)
                                .foregroundStyle(Catalyst.subtle)
                                .lineLimit(1)
                        }
                    }
                    .width(min: 140, ideal: 200)

                    TableColumn("PR", value: \.prSortKey) { branch in
                        BranchPRLink(pr: branch.associatedPR)
                    }
                    .width(min: 50, ideal: 60, max: 70)

                    TableColumn("Dev", value: \.mergedToDevelop) { branch in
                        MergeIndicator(status: branch.mergedToDevelop)
                    }
                    .width(35)

                    TableColumn("Main", value: \.mergedToMain) { branch in
                        MergeIndicator(status: branch.mergedToMain)
                    }
                    .width(35)

                    TableColumn("Committer", value: \.lastCommitter) { branch in
                        Text(branch.lastCommitter)
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundStyle(Catalyst.muted)
                            .lineLimit(1)
                    }
                    .width(min: 80, ideal: 120)

                    TableColumn("Activity", value: \.lastActivity) { branch in
                        Text(branch.lastActivityText)
                            .scaledFont(size: 11, design: .monospaced)
                            .foregroundStyle(Catalyst.muted)
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("Loc", value: \.location) { branch in
                        BranchLocationBadge(location: branch.location)
                    }
                    .width(35)
                } rows: {
                    ForEach(sortedBranches) { branch in
                        TableRow(branch)
                            .contextMenu {
                                Button("Copy Branch Name") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(branch.name, forType: .string)
                                }

                                if let pr = branch.associatedPR {
                                    Button("Open PR in Browser") {
                                        NSWorkspace.shared.open(pr.url)
                                    }
                                }

                                if branch.isDeletable {
                                    Divider()

                                    if branch.location != .local {
                                        Button("Delete Remote", role: .destructive) {
                                            Task { try? await store.deleteBranch(branch, remote: true, local: false) }
                                        }
                                    }
                                    if branch.location != .remote {
                                        Button("Delete Local", role: .destructive) {
                                            Task { try? await store.deleteBranch(branch, remote: false, local: true) }
                                        }
                                    }
                                    if branch.location == .both {
                                        Button("Delete Both", role: .destructive) {
                                            Task { try? await store.deleteBranch(branch, remote: true, local: true) }
                                        }
                                    }
                                }
                            }
                    }
                }
                .tableStyle(.inset)
                .scrollContentBackground(.hidden)
                .alternatingRowBackgrounds(.enabled)
                .tint(Catalyst.cyan)
                .overlay(alignment: .top) {
                    if store.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Catalyst.cyan)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.top, 8)
                    }
                }
            }

            if let error = store.error {
                BranchCleanupErrorBanner(message: error)
            }
        }
        .frame(minWidth: 700, idealWidth: 950, maxWidth: 1400, minHeight: 400, idealHeight: 600, maxHeight: 1000)
        .background(Catalyst.background)
        .foregroundStyle(Catalyst.foreground)
        .trackNavigation(path: "branchCleanup")
        .confirmationDialog(
            "Delete \(store.selectedBranchIDs.count) branch(es)?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Remote Only", role: .destructive) {
                Task { await store.deleteSelectedBranches(remote: true, local: false) }
            }
            Button("Delete Local Only", role: .destructive) {
                Task { await store.deleteSelectedBranches(remote: false, local: true) }
            }
            Button("Delete Both", role: .destructive) {
                Task { await store.deleteSelectedBranches(remote: true, local: true) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. Protected branches (main, master, develop) are excluded.")
        }
        .task {
            if !store.workspaceRoot.isEmpty && store.branches.isEmpty {
                await store.refreshAllBranches()
            }
        }
    }

    private func pickWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Workspace"
        panel.message = "Choose the folder containing your git repositories"

        if panel.runModal() == .OK, let url = panel.url {
            store.setWorkspaceRoot(url.path(percentEncoded: false))
        }
    }
}

// MARK: - Header Bar

struct BranchCleanupHeaderBar: View {
    let branchCount: Int
    let workspaceRoot: String
    let isLoading: Bool
    let onRefresh: () -> Void
    let onPickFolder: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("BRANCH CLEANUP")
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.cyan)

            if branchCount > 0 {
                Text("\(branchCount) branches")
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
            }

            Spacer()

            if !workspaceRoot.isEmpty {
                Text(workspaceRoot.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button("Refresh", systemImage: "arrow.clockwise", action: onRefresh)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(Catalyst.cyan)
                .disabled(isLoading)
                .catalystTooltip("Refresh branches")

            Button("Workspace Folder", systemImage: "folder", action: onPickFolder)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(Catalyst.muted)
                .catalystTooltip("Change workspace folder")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard()
    }
}

// MARK: - Filter Bar

struct BranchCleanupFilterBar: View {
    @Binding var searchQuery: String
    let hasBranches: Bool
    let selectedCount: Int
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDeleteSelected: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Catalyst.subtle)
                    .scaledFont(size: 10)
                TextField("Filter...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .scaledFont(size: 11, design: .monospaced)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Catalyst.surface, in: .rect(cornerRadius: Catalyst.radiusSM))
            .frame(maxWidth: 200)

            Spacer()

            if hasBranches {
                Button("Select All", action: onSelectAll)
                    .buttonStyle(.borderless)
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.muted)

                Button("Deselect", action: onDeselectAll)
                    .buttonStyle(.borderless)
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.muted)
            }

            if selectedCount > 0 {
                Button("Delete (\(selectedCount))", systemImage: "trash", action: onDeleteSelected)
                    .buttonStyle(.borderless)
                    .scaledFont(size: 11, weight: .medium)
                    .foregroundStyle(Catalyst.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

// MARK: - Error Banner

struct BranchCleanupErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Catalyst.yellow)
            Text(message)
                .scaledFont(size: 10, design: .monospaced)
                .foregroundStyle(Catalyst.muted)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Catalyst.surface)
    }
}
