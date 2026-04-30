import SwiftUI
import CatalystSwift

// MARK: - PR Link

struct BranchPRLink: View {
    let pr: BranchPRInfo?

    var body: some View {
        if let pr {
            Link(destination: pr.url) {
                HStack(spacing: 2) {
                    Text("#\(pr.number)")
                        .scaledFont(size: 11, design: .monospaced)
                    Circle()
                        .fill(prColor)
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityLabel("PR number \(pr.number), \(pr.state.lowercased())")
        } else {
            Text("—")
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
                .accessibilityLabel("No PR")
        }
    }

    private var prColor: Color {
        switch pr?.state {
        case "MERGED": Catalyst.magenta
        case "OPEN": Catalyst.cyan
        default: Catalyst.subtle
        }
    }
}

// MARK: - Merge Indicator

struct MergeIndicator: View {
    let status: MergeStatus

    var body: some View {
        Image(systemName: iconName)
            .foregroundStyle(iconColor)
            .scaledFont(size: 12)
            .accessibilityLabel(label)
    }

    private var iconName: String {
        switch status {
        case .merged: "checkmark.circle.fill"
        case .notMerged: "xmark.circle"
        case .unknown: "questionmark.circle"
        }
    }

    private var iconColor: Color {
        switch status {
        case .merged: Catalyst.cyan
        case .notMerged: Catalyst.red
        case .unknown: Catalyst.subtle
        }
    }

    private var label: String {
        switch status {
        case .merged: "Merged"
        case .notMerged: "Not merged"
        case .unknown: "Unknown"
        }
    }
}

// MARK: - Location Badge

struct BranchLocationBadge: View {
    let location: BranchLocation

    var body: some View {
        HStack(spacing: 2) {
            switch location {
            case .remote:
                Image(systemName: "cloud")
                    .scaledFont(size: 10)
                    .foregroundStyle(Catalyst.subtle)
            case .local:
                Image(systemName: "laptopcomputer")
                    .scaledFont(size: 10)
                    .foregroundStyle(Catalyst.yellow)
            case .both:
                Image(systemName: "cloud")
                    .scaledFont(size: 9)
                    .foregroundStyle(Catalyst.subtle)
                Image(systemName: "laptopcomputer")
                    .scaledFont(size: 9)
                    .foregroundStyle(Catalyst.subtle)
            }
        }
        .accessibilityLabel(label)
    }

    private var label: String {
        switch location {
        case .remote: "Remote only"
        case .local: "Local only"
        case .both: "Remote and local"
        }
    }
}
