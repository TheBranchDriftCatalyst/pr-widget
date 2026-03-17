import SwiftUI
import CatalystSwift

struct StatusBadge: View {
    let status: CIStatus
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .scaledFont(size: 11)
                .shadow(color: statusColor.opacity(0.5), radius: 3)
            Text(statusText)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(differentiateWithoutColor ? Catalyst.foreground : Catalyst.muted)
        }
        .accessibilityIdentifier(AccessibilityID.statusBadge)
        .accessibilityLabel("CI status: \(statusText)")
    }

    private var statusIcon: String {
        switch status {
        case .success: "checkmark.circle.fill"
        case .failure, .error: "xmark.circle.fill"
        case .pending: "clock.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch status {
        case .success: Catalyst.success
        case .failure, .error: Catalyst.failure
        case .pending: Catalyst.pending
        case .unknown: Catalyst.subtle
        }
    }

    private var statusText: String {
        switch status {
        case .success: "Passing"
        case .failure: "Failing"
        case .error: "Error"
        case .pending: "Pending"
        case .unknown: "No checks"
        }
    }
}
