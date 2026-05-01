import SwiftUI
import CatalystSwift

/// Shared chrome for collapsible comment surfaces: chevron toggle, leading
/// accent rail, background tint, and expand animation. Header and expanded
/// content are slots so call sites stay use-case specific (e.g. review thread
/// metadata vs. single comment author/timestamp).
struct CollapsibleCommentBlock<Header: View, Expanded: View>: View {
    let accentColor: Color
    let backgroundColor: Color
    let dimmed: Bool
    @ViewBuilder var header: () -> Header
    @ViewBuilder var expanded: () -> Expanded

    @State private var isExpanded: Bool

    init(
        accentColor: Color,
        backgroundColor: Color,
        dimmed: Bool = false,
        initiallyExpanded: Bool = false,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder expanded: @escaping () -> Expanded
    ) {
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.dimmed = dimmed
        self.header = header
        self.expanded = expanded
        self._isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .scaledFont(size: 8, weight: .bold)
                        .foregroundStyle(Catalyst.subtle)
                        .frame(width: 10)

                    header()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                expanded()
                    .padding(.leading, 20)
            }
        }
        .background(backgroundColor)
        .opacity(dimmed ? 0.6 : 1.0)
        .overlay(
            Rectangle()
                .fill(accentColor)
                .frame(width: 2),
            alignment: .leading
        )
    }
}
