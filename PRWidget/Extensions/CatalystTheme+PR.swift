import SwiftUI
import CatalystSwift

/// PR-specific color aliases extending the shared Catalyst theme.
extension Catalyst {
    // MARK: - Category Accents (PR sections)
    public static let needsAction = red
    public static let readyToShip = cyan
    public static let waiting = magenta

    // MARK: - Review State Colors
    public static let approved = cyan
    public static let changesRequested = red
    public static let commented = blue
    public static let dismissed = muted
    public static let pendingReview = blue

    // MARK: - Status Colors
    public static let pinned = Color(red: 0.961, green: 0.620, blue: 0.043) // amber #f59e0b
}
