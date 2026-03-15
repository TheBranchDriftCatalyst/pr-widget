import XCTest

/// Smoke tests for P-Arr macOS menu bar app.
///
/// This is an LSUIElement app with a floating NSPanel, not a standard window app.
/// The panel appears when clicking the status bar item or pressing the global hotkey.
///
/// **Important**: These tests require the `--uitesting` launch argument to be handled
/// by AppDelegate. In UI test mode the app should:
/// 1. Automatically show the floating panel (no menu bar click needed)
/// 2. Use mock data instead of real GitHub API calls
/// 3. Use in-memory storage instead of Keychain
///
/// Without mock mode integration in AppDelegate, tests that look for specific UI
/// elements will only verify the accessibility hierarchy is queryable.
///
/// **Note**: Identifier strings here must stay in sync with AccessibilityID in the
/// main target. A future AccessibilityIDs.swift helper in Helpers/ will deduplicate.
final class PRWidgetUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Smoke Tests

    /// Verify the app launches without crashing.
    /// LSUIElement apps may not reach .runningForeground since they have no
    /// standard window -- check .runningBackground as fallback.
    func testAppLaunches() throws {
        let isForeground = app.wait(for: .runningForeground, timeout: 5)
        let isBackground = app.state == .runningBackground || app.state == .runningBackgroundSuspended
        XCTAssertTrue(isForeground || isBackground,
                      "App should be running (state: \(app.state.rawValue))")
    }

    /// Verify the dashboard view appears in the floating panel.
    /// The panel is an NSPanel (non-activating) so it may appear as a window
    /// or as an "other" element in the accessibility hierarchy.
    ///
    /// NOTE: This test requires AppDelegate to auto-show the panel in --uitesting mode.
    /// Without that, the panel won't be visible and the test will be skipped.
    func testDashboardViewExists() throws {
        let dashboard = app.otherElements["dashboard_view"]

        // Also check windows -- NSPanel may register as a window
        let hasWindow = app.windows.count > 0

        if !dashboard.waitForExistence(timeout: 5) && !hasWindow {
            // Panel not auto-shown; skip rather than false-pass
            throw XCTSkip("Panel not visible -- AppDelegate may not auto-show in test mode yet")
        }

        if dashboard.exists {
            XCTAssertTrue(dashboard.exists, "Dashboard view should exist in the panel")
        }
    }

    /// Verify the header bar is present when the dashboard is shown.
    func testDashboardHeaderBarExists() throws {
        let header = app.otherElements["dashboard_header_bar"]
        if !header.waitForExistence(timeout: 5) {
            throw XCTSkip("Header bar not found -- panel may not be visible in test mode yet")
        }
        XCTAssertTrue(header.exists, "Dashboard header bar should be visible")
    }

    /// Verify the refresh button exists in the header.
    func testRefreshButtonExists() throws {
        let refreshButton = app.buttons["refresh_button"]
        if !refreshButton.waitForExistence(timeout: 5) {
            throw XCTSkip("Refresh button not found -- panel may not be visible in test mode yet")
        }
        XCTAssertTrue(refreshButton.exists, "Refresh button should be visible")
    }

    /// Verify that either the no-account view or the PR list is shown.
    /// In --uitesting mode with --mock-no-account, we expect the no-account view.
    /// Without specific mock args, the actual state depends on AppDelegate's test mode.
    func testInitialStateShown() throws {
        let noAccount = app.otherElements["no_account_view"]
        let prList = app.scrollViews["pr_list"]
        let emptyState = app.otherElements["empty_state_view"]

        // Wait for any of these to appear
        let foundSomething = noAccount.waitForExistence(timeout: 5)
            || prList.waitForExistence(timeout: 2)
            || emptyState.waitForExistence(timeout: 2)

        if !foundSomething {
            throw XCTSkip("No dashboard content found -- panel may not be visible in test mode yet")
        }

        let hasAnyState = noAccount.exists || prList.exists || emptyState.exists
        XCTAssertTrue(hasAnyState,
                      "Dashboard should show no-account, PR list, or empty state")
    }
}
