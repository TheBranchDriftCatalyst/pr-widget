import Foundation

/// A data model representing a contextual help tip.
///
/// Each tip has a category for grouping, a title, description, optional
/// keyboard shortcut, and an SF Symbol icon name. Tips are displayed by
/// ``HelpBadgeModifier`` (inline tooltips) and ``HelpSettingsView``
/// (full help reference page).
///
/// ## Usage
///
/// ```swift
/// let tip = HelpTip(
///     id: "toggle-dashboard",
///     category: "Navigation",
///     title: "Toggle Dashboard",
///     description: "Show or hide the floating dashboard.",
///     shortcut: "Cmd+Shift+Opt+P",
///     icon: "rectangle.on.rectangle"
/// )
/// ```
public struct HelpTip: Identifiable, Sendable {
    /// Unique identifier for this tip.
    public let id: String

    /// The grouping category (e.g., "Navigation", "Actions").
    public let category: String

    /// The tip title displayed prominently.
    public let title: String

    /// A detailed description of what this tip explains.
    public let description: String

    /// An optional keyboard shortcut string (e.g., `"Cmd+R"`).
    public let shortcut: String?

    /// An SF Symbol name for the tip icon.
    public let icon: String

    /// Creates a help tip.
    /// - Parameters:
    ///   - id: A unique identifier.
    ///   - category: The grouping category.
    ///   - title: The tip title.
    ///   - description: The detailed description.
    ///   - shortcut: An optional keyboard shortcut display string.
    ///   - icon: An SF Symbol name.
    public init(id: String, category: String, title: String, description: String, shortcut: String? = nil, icon: String) {
        self.id = id
        self.category = category
        self.title = title
        self.description = description
        self.shortcut = shortcut
        self.icon = icon
    }
}
