import SwiftUI
import CatalystSwift

struct DashboardHeaderBar: View {
    @Environment(PollingScheduler.self) private var polling

    let lastRefreshed: Date?
    let isLoading: Bool
    let isPinned: Bool
    let blockedByMe: Int
    let ownedByMe: Int
    let readyForQA: Int
    let onRefresh: () -> Void
    let onTogglePin: () -> Void
    let onOpenSettings: () -> Void

    private var intervalLabel: String {
        let s = Int(polling.interval)
        if s >= 60 { return "\(s / 60)m" }
        return "\(s)s"
    }

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
                HStack(spacing: 4) {
                    Text(lastRefreshed, style: .relative)
                    if polling.isEnabled {
                        Text("(\(intervalLabel))")
                            .foregroundStyle(Catalyst.subtle)
                    }
                }
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
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise")
                        if polling.isEnabled {
                            Circle()
                                .fill(Catalyst.approved)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .foregroundStyle(Catalyst.cyan)
                }
            }
            .buttonStyle(.borderless)
            .disabled(isLoading)
            .accessibilityIdentifier(AccessibilityID.refreshButton)
            .accessibilityLabel("Refresh")
            .help(polling.isEnabled ? "Auto-refresh every \(intervalLabel)" : "Refresh")

            Button {
                onTogglePin()
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin.slash")
                    .foregroundStyle(isPinned ? Catalyst.cyan : Catalyst.muted)
            }
            .buttonStyle(.borderless)
            .accessibilityIdentifier(AccessibilityID.pinButton)
            .help(isPinned ? "Unpin window" : "Pin window on top")

            Button("Settings", systemImage: "gearshape", action: onOpenSettings)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(Catalyst.muted)
                .accessibilityIdentifier(AccessibilityID.settingsButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassCard()
        .accessibilityIdentifier(AccessibilityID.dashboardHeaderBar)
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
