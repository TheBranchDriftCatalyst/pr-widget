import SwiftUI
import CatalystSwift

struct PRRowView: View {
    let pr: PullRequest
    let accentColor: Color

    @Environment(DashboardStore.self) private var store
    @Environment(AccountManager.self) private var accountManager

    private var prAccessibilityLabel: String {
        var parts = [pr.title, pr.repository.nameWithOwner, "number \(pr.number)"]
        if pr.isDraft { parts.append("draft") }
        parts.append("CI \(pr.statusCheckRollup.rawValue.lowercased())")
        parts.append("age \(pr.ageText)")
        if pr.mergeable == .conflicting { parts.append("has conflicts") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        Button {
            NSWorkspace.shared.open(pr.url)
        } label: {
            HStack(spacing: 0) {
                // Left accent border — neon stripe
                GradientAccentStripe(color: accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    // Title row
                    HStack(alignment: .top, spacing: 6) {
                        if pr.isDraft {
                            Image(systemName: "doc")
                                .font(.caption)
                                .foregroundStyle(Catalyst.subtle)
                                .accessibilityLabel("Draft")
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pr.title)
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundStyle(Catalyst.foreground)
                                .lineLimit(2)

                            Text("\(pr.repository.nameWithOwner) #\(pr.number)")
                                .scaledFont(size: 11, design: .monospaced)
                                .foregroundStyle(Catalyst.muted)
                        }

                        Spacer()

                        UrgencyBadge(ageText: pr.ageText, urgencyScore: pr.urgencyScore)
                    }

                    // Status row
                    HStack(spacing: 8) {
                        StatusBadge(status: pr.statusCheckRollup)

                        ReviewAvatars(reviews: pr.reviews, reviewRequests: pr.reviewRequests)

                        if pr.mergeable == .conflicting {
                            Label("Conflicts", systemImage: "exclamationmark.triangle.fill")
                                .scaledFont(size: 11)
                                .foregroundStyle(Catalyst.warning)
                        }

                        Spacer()

                        // Lines changed
                        HStack(spacing: 2) {
                            Text("+\(pr.additions)")
                                .foregroundStyle(Catalyst.cyan)
                            Text("-\(pr.deletions)")
                                .foregroundStyle(Catalyst.red)
                        }
                        .scaledFont(size: 11, design: .monospaced)
                    }

                    // Labels
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
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.prRow(id: pr.id))
        .accessibilityLabel(prAccessibilityLabel)
        .accessibilityHint("Opens pull request in browser")
        .hoverGlow(accentColor)
        .contextMenu {
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
}
