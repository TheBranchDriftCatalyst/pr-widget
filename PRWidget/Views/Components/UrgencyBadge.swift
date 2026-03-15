import SwiftUI
import CatalystSwift

struct UrgencyBadge: View {
    let ageText: String
    let urgencyScore: Double
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 2) {
            if differentiateWithoutColor, let indicator = urgencyIndicator {
                Text(indicator)
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundStyle(urgencyColor)
            }
            Text(ageText)
                .scaledFont(size: 12, weight: .medium, design: .monospaced)
                .foregroundStyle(urgencyColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(urgencyColor.opacity(0.15), in: RoundedRectangle(cornerRadius: Catalyst.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                .strokeBorder(urgencyColor.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: urgencyColor.opacity(0.3), radius: 3)
        .accessibilityIdentifier(AccessibilityID.urgencyBadge)
        .accessibilityLabel("Age \(ageText), urgency \(urgencyLabel)")
    }

    private var urgencyColor: Color {
        if urgencyScore >= 6 { return Catalyst.red }
        if urgencyScore >= 4 { return Catalyst.warning }
        if urgencyScore >= 2 { return Catalyst.yellow }
        return Catalyst.muted
    }

    private var urgencyIndicator: String? {
        if urgencyScore >= 6 { return "!!!" }
        if urgencyScore >= 4 { return "!!" }
        if urgencyScore >= 2 { return "!" }
        return nil
    }

    private var urgencyLabel: String {
        if urgencyScore >= 6 { return "critical" }
        if urgencyScore >= 4 { return "high" }
        if urgencyScore >= 2 { return "moderate" }
        return "low"
    }
}
