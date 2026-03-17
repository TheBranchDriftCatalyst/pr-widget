import SwiftUI

/// A horizontal wrapping layout that flows items left-to-right and wraps to new rows.
///
/// `FlowLayout` conforms to SwiftUI's `Layout` protocol. Items are placed
/// left-to-right until the next item would exceed the proposed width, at
/// which point a new row begins. The same spacing value is used for both
/// horizontal gaps and vertical row gaps.
///
/// ## Usage
///
/// ```swift
/// FlowLayout(spacing: 6) {
///     ForEach(tags, id: \.self) { tag in
///         Text(tag)
///             .font(Catalyst.label())
///             .padding(.horizontal, 8)
///             .padding(.vertical, 4)
///             .background(Catalyst.cyan.opacity(0.15))
///             .clipShape(.rect(cornerRadius: Catalyst.radiusSM))
///     }
/// }
/// ```
public struct FlowLayout: Layout {
    /// The spacing between items, both horizontally and vertically.
    public var spacing: CGFloat

    /// Creates a flow layout.
    /// - Parameter spacing: The gap between items. Defaults to `4`.
    public init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
