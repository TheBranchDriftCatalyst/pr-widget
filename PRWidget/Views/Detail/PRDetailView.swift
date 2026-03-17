import SwiftUI
import CatalystSwift

struct PRDetailView: View {
    let pr: PullRequest

    @Environment(DashboardStore.self) var store
    @Environment(AccountManager.self) var accountManager
    @Environment(SynopsisEngine.self) var synopsisEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openDiffPanel) private var openDiffPanel
    @State private var detail: PRDetail?
    @State private var synopsis: AISynopsis?
    @State private var isLoadingDetail = true
    @State private var actionError: String?

    @State private var actionHandler = ActionHandler()

    var body: some View {
        VStack(spacing: 0) {
            // Back bar
            HStack(spacing: 6) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .scaledFont(size: 11, weight: .semibold)
                        Text("BACK")
                            .scaledFont(size: 10, weight: .bold, design: .monospaced)
                            .tracking(1)
                    }
                    .foregroundStyle(Catalyst.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Text(pr.repository.nameWithOwner)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)

                Text("#\(pr.number)")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundStyle(Catalyst.cyan)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassCard()
            GlowDivider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    detailHeader
                    GlowDivider()

                    if pr.state == .open && !pr.isDraft {
                        quickActionsSection
                        GlowDivider()
                    }

                if isLoadingDetail {
                    loadingView
                } else if let detail {
                    synopsisSection
                    GlowDivider()

                    if !detail.checkRuns.isEmpty {
                        checksSection(detail.checkRuns)
                        GlowDivider()
                    }

                    activitySection(detail)
                } else {
                    errorView
                }
                }
            }
            .task { await loadDetail() }
        }
        .background(Catalyst.background)
        .toolbar(.hidden, for: .automatic)
    }

    // MARK: - Header

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                stateBadge
                Text(pr.repository.nameWithOwner)
                    .scaledFont(size: 11, weight: .medium, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)
                Spacer()
                Text("#\(pr.number)")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundStyle(Catalyst.cyan)
            }

            Text(pr.title)
                .scaledFont(size: 15, weight: .semibold)
                .foregroundStyle(Catalyst.foreground)

            HStack(spacing: 4) {
                Text(pr.headRefName)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Catalyst.cyan.opacity(0.1), in: .rect(cornerRadius: Catalyst.radiusSM))
                    .shadow(color: Catalyst.cyan.opacity(0.2), radius: 2)
                Image(systemName: "arrow.right")
                    .scaledFont(size: 8)
                    .foregroundStyle(Catalyst.subtle)
                Text(pr.baseRefName)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.magenta)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Catalyst.magenta.opacity(0.1), in: .rect(cornerRadius: Catalyst.radiusSM))
                    .shadow(color: Catalyst.magenta.opacity(0.2), radius: 2)
            }

            HStack(spacing: 8) {
                Label(pr.author.login, systemImage: "person")
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.muted)

                Label(pr.ageText, systemImage: "clock")
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.muted)

                Spacer()

                HStack(spacing: 2) {
                    Text("+\(pr.additions)")
                        .foregroundStyle(Catalyst.cyan)
                    Text("-\(pr.deletions)")
                        .foregroundStyle(Catalyst.red)
                }
                .scaledFont(size: 11, design: .monospaced)

                if let detail {
                    Text("\(detail.changedFiles) files")
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.subtle)
                }
            }

            HStack(spacing: 8) {
                Button {
                    NSWorkspace.shared.open(pr.url)
                } label: {
                    Label("Open in GitHub", systemImage: "arrow.up.right")
                        .scaledFont(size: 11, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.background)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Catalyst.cyan, in: .rect(cornerRadius: Catalyst.radiusMD))
                }
                .buttonStyle(.plain)
                .hoverGlow(Catalyst.cyan)

                Button {
                    openDiffPanel(pr)
                } label: {
                    Label("View Diff", systemImage: "doc.text.magnifyingglass")
                        .scaledFont(size: 11, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.magenta)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Catalyst.magenta.opacity(0.15), in: .rect(cornerRadius: Catalyst.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                                .strokeBorder(Catalyst.magenta.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .hoverGlow(Catalyst.magenta)
            }
        }
        .padding(12)
        .glassCard()
    }

    private var stateBadge: some View {
        let (icon, color, text): (String, Color, String) = switch pr.state {
        case .open: ("circle.fill", Catalyst.cyan, "OPEN")
        case .merged: ("arrow.triangle.merge", Catalyst.magenta, "MERGED")
        case .closed: ("xmark.circle.fill", Catalyst.red, "CLOSED")
        }

        return Label(text, systemImage: icon)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .shadow(color: color.opacity(0.4), radius: 3)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 4) {
            QuickActionsView(
                pr: pr,
                onApprove: { Task { await performApprove() } },
                onMerge: { method in Task { await performMerge(method: method) } },
                onRequestChanges: { comment in Task { await performRequestChanges(comment: comment) } }
            )
            .padding(12)

            if let actionError {
                Text(actionError)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Synopsis

    private var synopsisSection: some View {
        SynopsisCard(synopsis: synopsis, isLoading: isLoadingDetail)
            .padding(12)
    }

    // MARK: - Checks

    private func checksSection(_ checks: [PRCheckRun]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "CHECKS")
                .padding(.bottom, 4)

            ForEach(checks) { check in
                HStack(spacing: 6) {
                    checkIcon(for: check)
                    Text(check.name)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundStyle(Catalyst.foreground)
                        .lineLimit(1)
                    Spacer()
                    if let conclusion = check.conclusion {
                        Text(conclusion.lowercased())
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundStyle(Catalyst.subtle)
                    }
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    private func checkIcon(for check: PRCheckRun) -> some View {
        let color: Color = switch check.ciStatus {
        case .success: Catalyst.success
        case .failure: Catalyst.failure
        case .pending: Catalyst.pending
        case .error: Catalyst.warning
        case .unknown: Catalyst.subtle
        }

        return Group {
            switch check.ciStatus {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Catalyst.success)
            case .failure:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Catalyst.failure)
            case .pending:
                Image(systemName: "clock.fill")
                    .foregroundStyle(Catalyst.pending)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Catalyst.warning)
            case .unknown:
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(Catalyst.subtle)
            }
        }
        .scaledFont(size: 12)
        .shadow(color: color.opacity(0.5), radius: 3)
    }

    // MARK: - Activity

    private func activitySection(_ detail: PRDetail) -> some View {
        ActivityFeed(activities: detail.allActivity)
            .padding(12)
    }

    // MARK: - Loading/Error

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .controlSize(.small)
                .tint(Catalyst.cyan)
            Text("LOADING DETAILS...")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
        .shimmerLoading()
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .scaledFont(size: 18)
                .foregroundStyle(Catalyst.warning)
            Text("Failed to load details")
                .scaledFont(size: 11)
                .foregroundStyle(Catalyst.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func performApprove() async {
        guard let (token, endpoint) = accountCredentials else { return }
        actionError = nil
        do {
            try await actionHandler.approve(pr: pr, comment: nil, token: token, endpoint: endpoint)
            await store.refresh()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func performMerge(method: MergeMethod) async {
        guard let (token, endpoint) = accountCredentials else { return }
        actionError = nil
        do {
            try await actionHandler.merge(pr: pr, method: method, token: token, endpoint: endpoint)
            await store.refresh()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func performRequestChanges(comment: String) async {
        guard let (token, endpoint) = accountCredentials else { return }
        actionError = nil
        do {
            try await actionHandler.requestChanges(pr: pr, comment: comment, token: token, endpoint: endpoint)
            await store.refresh()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private var accountCredentials: (token: String, endpoint: URL)? {
        guard let account = accountManager.accounts.first,
              let token = accountManager.token(for: account) else { return nil }
        return (token, account.graphQLEndpoint)
    }

    // MARK: - Data Loading

    private func loadDetail() async {
        isLoadingDetail = true
        detail = await store.fetchDetail(for: pr)
        isLoadingDetail = false

        if let detail {
            synopsis = await synopsisEngine.generateSynopsis(for: pr, detail: detail)
        }
    }
}
