import SwiftUI

/// A view modifier that attaches a help tooltip (and optional "?" badge) to a view.
///
/// When `showBadge` is `true`, a small "?" circle icon appears in the
/// top-right corner of the view. In both cases, the native macOS tooltip
/// displays the tip's description on hover.
///
/// ## Usage
///
/// ```swift
/// // Tooltip only (no visual badge)
/// Button("Action") { /* ... */ }
///     .helpTip(myTip)
///
/// // Tooltip with visible "?" badge
/// Image(systemName: "gear")
///     .helpTip(myTip, showBadge: true)
/// ```
public struct HelpBadgeModifier: ViewModifier {
    /// The help tip to display.
    public let tip: HelpTip

    /// Whether to show a small "?" badge icon on the view.
    public var showBadge: Bool = false

    /// Creates a help badge modifier.
    /// - Parameters:
    ///   - tip: The help tip data.
    ///   - showBadge: Whether to show the "?" indicator. Defaults to `false`.
    public init(tip: HelpTip, showBadge: Bool = false) {
        self.tip = tip
        self.showBadge = showBadge
    }

    public func body(content: Content) -> some View {
        if showBadge {
            content
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "questionmark.circle.fill")
                        .scaledFont(size: 8)
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
    /// Attaches a help tip tooltip to this view.
    ///
    /// Shows a native macOS tooltip with the tip's description on hover.
    /// Set `showBadge: true` to also display a small "?" indicator.
    ///
    /// ```swift
    /// Text("Status")
    ///     .helpTip(statusTip, showBadge: true)
    /// ```
    ///
    /// - Parameters:
    ///   - tip: The ``HelpTip`` to display.
    ///   - showBadge: Whether to show a "?" badge. Defaults to `false`.
    func helpTip(_ tip: HelpTip, showBadge: Bool = false) -> some View {
        modifier(HelpBadgeModifier(tip: tip, showBadge: showBadge))
    }
}
