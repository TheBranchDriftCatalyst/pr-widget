import SwiftUI
import CatalystSwift

struct DashboardHeaderBar: View {
    let lastRefreshed: Date?
    let isLoading: Bool
    let isPinned: Bool
    let blockedByMe: Int
    let ownedByMe: Int
    let readyForQA: Int
    let onRefresh: () -> Void
    let onTogglePin: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("PR WIDGET")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Catalyst.cyan)
                    Text("v\(Bundle.main.appVersion)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Catalyst.subtle)
                }
            }

            // Summary counts
            if blockedByMe > 0 || ownedByMe > 0 || readyForQA > 0 {
                HStack(spacing: 6) {
                    if blockedByMe > 0 {
                        countBadge(blockedByMe, color: Catalyst.red, icon: "hand.raised.fill", label: "Blocked by you")
                    }
                    if ownedByMe > 0 {
                        countBadge(ownedByMe, color: Catalyst.cyan, icon: "person.fill", label: "Your PRs")
                    }
                    if readyForQA > 0 {
                        countBadge(readyForQA, color: Catalyst.approved, icon: "checkmark.circle.fill", label: "Ready for QA")
                    }
                }
            }

            Spacer()

            if let lastRefreshed {
                Text(lastRefreshed, style: .relative)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(Catalyst.muted)
            }

            Button {
                onRefresh()
            } label: {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Catalyst.cyan)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Catalyst.cyan)
                }
            }
            .buttonStyle(.borderless)
            .disabled(isLoading)
            .accessibilityLabel("Refresh")

            Button {
                onTogglePin()
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin.slash")
                    .foregroundStyle(isPinned ? Catalyst.cyan : Catalyst.muted)
            }
            .buttonStyle(.borderless)
            .help(isPinned ? "Unpin window" : "Pin window on top")

            Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(Catalyst.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard()
    }

    private func countBadge(_ count: Int, color: Color, icon: String, label: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text("\(count)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(color)
        .help(label)
    }
}
