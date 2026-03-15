import SwiftUI

/// View modifier that wraps content with a help indicator.
/// Adds a small "?" badge and tooltip with the tip description.
public struct HelpBadgeModifier: ViewModifier {
    public let tip: HelpTip
    public var showBadge: Bool = false

    public init(tip: HelpTip, showBadge: Bool = false) {
        self.tip = tip
        self.showBadge = showBadge
    }

    public func body(content: Content) -> some View {
        if showBadge {
            content
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Catalyst.subtle)
                        .offset(x: 4, y: -4)
                }
                .help(tip.description)
        } else {
            content
                .help(tip.description)
        }
    }
}

public extension View {
    /// Attach a help tip to this view. Shows a tooltip with the description.
    /// Set `showBadge: true` to also display a small "?" indicator.
    func helpTip(_ tip: HelpTip, showBadge: Bool = false) -> some View {
        modifier(HelpBadgeModifier(tip: tip, showBadge: showBadge))
    }
}
