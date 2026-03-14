import Foundation
import CatalystSwift

enum HelpCategory: String, CaseIterable {
    case shortcuts = "Keyboard Shortcuts"
    case labels = "Label Filters"
    case navigation = "Navigation"
    case actions = "PR Actions"
}

extension HelpTip {
    static let all: [HelpTip] = [
        // MARK: - Keyboard Shortcuts
        HelpTip(
            id: "hotkey-toggle",
            category: HelpCategory.shortcuts.rawValue,
            title: "Toggle Panel",
            description: "Show or hide the PR Widget floating panel from anywhere on your Mac.",
            shortcut: "⌘⇧⌥P",
            icon: "rectangle.on.rectangle"
        ),

        // MARK: - Label Filters
        HelpTip(
            id: "label-include",
            category: HelpCategory.labels.rawValue,
            title: "Include Label",
            description: "Click a label chip to filter — only PRs with that label are shown. Chip turns yellow.",
            shortcut: "Click",
            icon: "tag"
        ),
        HelpTip(
            id: "label-exclude",
            category: HelpCategory.labels.rawValue,
            title: "Exclude Label",
            description: "Cmd+Click a label chip to exclude — PRs with that label are hidden. Chip turns red with strikethrough.",
            shortcut: "⌘+Click",
            icon: "tag.slash"
        ),
        HelpTip(
            id: "label-cross-toggle",
            category: HelpCategory.labels.rawValue,
            title: "Switch Filter Mode",
            description: "Cmd+Click an included (yellow) label to switch it to excluded (red), or Click an excluded label to switch it to included.",
            icon: "arrow.triangle.2.circlepath"
        ),

        // MARK: - Navigation
        HelpTip(
            id: "repo-collapse",
            category: HelpCategory.navigation.rawValue,
            title: "Collapse/Expand Repo",
            description: "Click a repo header to toggle that repo section open or closed.",
            shortcut: "Click",
            icon: "chevron.down"
        ),
        HelpTip(
            id: "repo-collapse-all",
            category: HelpCategory.navigation.rawValue,
            title: "Collapse/Expand All",
            description: "Cmd+Click any repo header to collapse or expand all repo sections at once.",
            shortcut: "⌘+Click",
            icon: "rectangle.compress.vertical"
        ),
        HelpTip(
            id: "repo-reorder",
            category: HelpCategory.navigation.rawValue,
            title: "Reorder Repos",
            description: "Drag a repo header up or down to customize the display order. Order persists across sessions.",
            shortcut: "Drag",
            icon: "line.3.horizontal"
        ),
        HelpTip(
            id: "search-filter",
            category: HelpCategory.navigation.rawValue,
            title: "Search",
            description: "Search filters by PR title, repository name, branch name, and author login.",
            icon: "magnifyingglass"
        ),

        // MARK: - PR Actions
        HelpTip(
            id: "pr-context-menu",
            category: HelpCategory.actions.rawValue,
            title: "PR Context Menu",
            description: "Right-click any PR row to access quick actions: Pin/Unpin, Open in Browser, Copy URL, Copy Branch, and Label management.",
            shortcut: "Right-Click",
            icon: "contextualmenu.and.cursorarrow"
        ),
        HelpTip(
            id: "label-add-remove",
            category: HelpCategory.actions.rawValue,
            title: "Add/Remove Labels",
            description: "Right-click a PR → Labels submenu. Labels already on the PR show a checkmark — click to remove. Labels not on the PR can be clicked to add.",
            shortcut: "Right-Click → Labels",
            icon: "tag.circle"
        ),
        HelpTip(
            id: "label-recycle",
            category: HelpCategory.actions.rawValue,
            title: "Re-apply Label",
            description: "Right-click a PR → Labels → Re-apply. Removes then re-adds the label to re-trigger GitHub webhook/action hooks.",
            shortcut: "Right-Click → Labels → Re-apply",
            icon: "arrow.triangle.2.circlepath"
        ),
        HelpTip(
            id: "pr-pin",
            category: HelpCategory.actions.rawValue,
            title: "Pin PR",
            description: "Pin important PRs to keep them visible at the top in a dedicated \"Pinned\" section, regardless of repo grouping.",
            shortcut: "Right-Click → Pin",
            icon: "pin"
        ),
    ]

    static func tips(for category: HelpCategory) -> [HelpTip] {
        all.filter { $0.category == category.rawValue }
    }
}
