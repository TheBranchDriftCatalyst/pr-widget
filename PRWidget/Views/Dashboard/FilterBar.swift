import SwiftUI
import CatalystSwift

struct FilterBar: View {
    @Binding var activeFilter: PRFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(PRFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isActive: activeFilter == filter,
                        action: { activeFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .accessibilityIdentifier(AccessibilityID.filterBar)
        .background(Catalyst.card)
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(isActive ? Catalyst.background : Catalyst.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? Catalyst.cyan : Catalyst.surface, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isActive ? Color.clear : Catalyst.border, lineWidth: 1)
                )
                .if(isActive) { $0.neonGlow(Catalyst.cyan, radius: 6) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.filterChip(name: title))
    }
}
