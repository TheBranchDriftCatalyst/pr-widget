import SwiftUI
import CatalystSwift

struct PRDetailView: View {
    let pr: PullRequest

    @Environment(DashboardStore.self) var store
    @Environment(SynopsisEngine.self) var synopsisEngine
    @Environment(\.dismiss) private var dismiss
    @State private var detail: PRDetail?
    @State private var synopsis: AISynopsis?
    @State private var isLoadingDetail = true

    var body: some View {
        VStack(spacing: 0) {
            // Back bar
            HStack(spacing: 6) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("BACK")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1)
                    }
                    .foregroundStyle(Catalyst.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(pr.repository.nameWithOwner)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Catalyst.muted)

                Text("#\(pr.number)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Catalyst.muted)
                Spacer()
                Text("#\(pr.number)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Catalyst.cyan)
            }

            Text(pr.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Catalyst.foreground)

            HStack(spacing: 4) {
                Text(pr.headRefName)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Catalyst.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Catalyst.cyan.opacity(0.1), in: .rect(cornerRadius: 3))
                    .shadow(color: Catalyst.cyan.opacity(0.2), radius: 2)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundStyle(Catalyst.subtle)
                Text(pr.baseRefName)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Catalyst.magenta)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Catalyst.magenta.opacity(0.1), in: .rect(cornerRadius: 3))
                    .shadow(color: Catalyst.magenta.opacity(0.2), radius: 2)
            }

            HStack(spacing: 8) {
                Label(pr.author.login, systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(Catalyst.muted)

                Label(pr.ageText, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(Catalyst.muted)

                Spacer()

                HStack(spacing: 2) {
                    Text("+\(pr.additions)")
                        .foregroundStyle(Catalyst.cyan)
                    Text("-\(pr.deletions)")
                        .foregroundStyle(Catalyst.red)
                }
                .font(.system(size: 11, design: .monospaced))

                if let detail {
                    Text("\(detail.changedFiles) files")
                        .font(.caption)
                        .foregroundStyle(Catalyst.subtle)
                }
            }

            Button {
                NSWorkspace.shared.open(pr.url)
            } label: {
                Label("Open in GitHub", systemImage: "arrow.up.right")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Catalyst.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Catalyst.cyan, in: .rect(cornerRadius: Catalyst.cornerRadius))
            }
            .buttonStyle(.plain)
            .hoverGlow(Catalyst.cyan)
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
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .shadow(color: color.opacity(0.4), radius: 3)
    }

    // MARK: - Synopsis

    private var synopsisSection: some View {
        SynopsisCard(synopsis: synopsis, isLoading: isLoadingDetail)
            .padding(12)
    }

    // MARK: - Checks

    private func checksSection(_ checks: [PRCheckRun]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CHECKS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Catalyst.muted)
                .padding(.bottom, 4)

            ForEach(checks) { check in
                HStack(spacing: 6) {
                    checkIcon(for: check)
                    Text(check.name)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Catalyst.foreground)
                        .lineLimit(1)
                    Spacer()
                    if let conclusion = check.conclusion {
                        Text(conclusion.lowercased())
                            .font(.system(size: 10, design: .monospaced))
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
        .font(.system(size: 12))
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
                .font(.system(size: 10, weight: .bold, design: .monospaced))
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
                .font(.title3)
                .foregroundStyle(Catalyst.warning)
            Text("Failed to load details")
                .font(.caption)
                .foregroundStyle(Catalyst.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
