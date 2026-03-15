import SwiftUI
import CatalystSwift

struct FilterBar: View {
    @Binding var activeFilter: PRFilter

    var body: some View {
        VStack(spacing: 0) {
            // Primary row: triage categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(PRFilter.triageFilters, id: \.self) { filter in
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
            .background(Catalyst.card)

            // Secondary row: perspective filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(PRFilter.perspectiveFilters, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isActive: activeFilter == filter,
                            style: .secondary,
                            action: { activeFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .background(Catalyst.surface)
        }
        .accessibilityIdentifier(AccessibilityID.filterBar)
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary, secondary
    }

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .scaledFont(size: style == .primary ? 10 : 9, weight: .semibold, design: .monospaced)
                .tracking(0.5)
                .foregroundStyle(isActive ? Catalyst.background : Catalyst.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? accentColor : Catalyst.surface, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isActive ? Color.clear : Catalyst.border, lineWidth: 1)
                )
                .if(isActive) { $0.neonGlow(accentColor, radius: 6) }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.filterChip(name: title))
        .accessibilityLabel("\(title) filter")
        .accessibilityHint(isActive ? "Currently selected" : "Double-tap to filter")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var accentColor: Color {
        style == .primary ? Catalyst.cyan : Catalyst.magenta
    }
}
