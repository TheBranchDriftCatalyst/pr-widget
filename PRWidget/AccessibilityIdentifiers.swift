import Foundation

/// Centralized accessibility identifiers for UI testing.
/// Used by both the app views and XCUITest target.
enum AccessibilityID {
    // MARK: - Dashboard
    static let dashboardView = "dashboard_view"
    static let dashboardHeaderBar = "dashboard_header_bar"
    static let refreshButton = "refresh_button"
    static let pinButton = "pin_button"
    static let settingsButton = "settings_button"

    // MARK: - Filters & Search
    static let filterBar = "filter_bar"
    static let searchBar = "search_bar"
    static let searchField = "search_field"
    static let searchClearButton = "search_clear_button"

    // MARK: - PR List
    static let prList = "pr_list"
    static let prRow = "pr_row"              // suffix with PR id
    static let pinnedSection = "pinned_section"
    static let repoGroupSection = "repo_group" // suffix with repo name

    // MARK: - PR Row Components
    static let urgencyBadge = "urgency_badge" // suffix with PR id
    static let statusBadge = "status_badge"
    static let reviewAvatars = "review_avatars"

    // MARK: - Empty / Error States
    static let noAccountView = "no_account_view"
    static let emptyStateView = "empty_state_view"
    static let noMatchView = "no_match_view"
    static let errorBanner = "error_banner"

    // MARK: - Filter Chips
    static let filterChip = "filter_chip" // suffix with filter name

    // MARK: - Detail View
    static let prDetailView = "pr_detail_view"

    // MARK: - Settings
    static let settingsWindow = "settings_window"

    // MARK: - Helpers
    static func prRow(id: String) -> String { "\(prRow)_\(id)" }
    static func urgencyBadge(id: String) -> String { "\(urgencyBadge)_\(id)" }
    static func repoGroup(name: String) -> String { "\(repoGroupSection)_\(name)" }
    static func filterChip(name: String) -> String { "\(filterChip)_\(name)" }
}
