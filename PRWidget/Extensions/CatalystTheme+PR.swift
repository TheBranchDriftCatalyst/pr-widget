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
    public static let pendingReview = yellow
}
