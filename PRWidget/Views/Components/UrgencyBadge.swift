import SwiftUI
import CatalystSwift

struct UrgencyBadge: View {
    let ageText: String
    let urgencyScore: Double

    var body: some View {
        Text(ageText)
            .font(.caption)
            .fontWeight(.medium)
            .fontDesign(.monospaced)
            .foregroundStyle(urgencyColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(urgencyColor.opacity(0.15), in: RoundedRectangle(cornerRadius: Catalyst.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Catalyst.cornerRadius)
                    .strokeBorder(urgencyColor.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: urgencyColor.opacity(0.3), radius: 3)
    }

    private var urgencyColor: Color {
        if urgencyScore >= 6 { return Catalyst.red }
        if urgencyScore >= 4 { return Catalyst.warning }
        if urgencyScore >= 2 { return Catalyst.yellow }
        return Catalyst.muted
    }
}
