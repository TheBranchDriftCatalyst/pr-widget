import XCTest
@testable import CatalystSwift

final class ChangelogParserTests: XCTestCase {

    func testBasicParsing() {
        let markdown = """
        # Changelog

        ## [0.2.0] - 2026-03-10

        ### Added

        - **auth**: Multi-account support
        - Global hotkey toggle

        ### Fixed

        - **polling**: Timer leak on window close
        - Crash on empty response

        ## [0.1.0] - 2026-02-15

        ### Added

        - Initial release
        """

        let releases = ChangelogParser.parse(markdown)

        XCTAssertEqual(releases.count, 2)

        let first = releases[0]
        XCTAssertEqual(first.version, "0.2.0")
        XCTAssertEqual(first.date, "2026-03-10")
        XCTAssertEqual(first.sections.count, 2)

        let added = first.sections[0]
        XCTAssertEqual(added.title, "Added")
        XCTAssertEqual(added.entries.count, 2)
        XCTAssertEqual(added.entries[0].scope, "auth")
        XCTAssertEqual(added.entries[0].message, "Multi-account support")
        XCTAssertNil(added.entries[1].scope)
        XCTAssertEqual(added.entries[1].message, "Global hotkey toggle")

        let fixed = first.sections[1]
        XCTAssertEqual(fixed.title, "Fixed")
        XCTAssertEqual(fixed.entries.count, 2)
        XCTAssertEqual(fixed.entries[0].scope, "polling")

        let second = releases[1]
        XCTAssertEqual(second.version, "0.1.0")
        XCTAssertEqual(second.date, "2026-02-15")
        XCTAssertEqual(second.sections.count, 1)
    }

    func testBreakingChanges() {
        let markdown = """
        ## [1.0.0] - 2026-03-01

        ### Breaking Changes

        - **breaking** Removed legacy auth flow
        - **BREAKING** Changed API response format
        """

        let releases = ChangelogParser.parse(markdown)
        XCTAssertEqual(releases.count, 1)

        let entries = releases[0].sections[0].entries
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries[0].isBreaking)
        XCTAssertEqual(entries[0].message, "Removed legacy auth flow")
        XCTAssertTrue(entries[1].isBreaking)
    }

    func testVersionWithoutDate() {
        let markdown = """
        ## [Unreleased]

        ### Added

        - Work in progress feature
        """

        let releases = ChangelogParser.parse(markdown)
        XCTAssertEqual(releases.count, 1)
        XCTAssertEqual(releases[0].version, "Unreleased")
        XCTAssertNil(releases[0].date)
    }

    func testEmptyInput() {
        let releases = ChangelogParser.parse("# Changelog\n\nNothing here yet.")
        XCTAssertTrue(releases.isEmpty)
    }

    func testScopedEntries() {
        let markdown = """
        ## [0.1.0] - 2026-01-01

        ### Changed

        - **ui**: Redesigned dashboard layout
        - **api**: Updated GraphQL queries
        - Simple change without scope
        """

        let releases = ChangelogParser.parse(markdown)
        let entries = releases[0].sections[0].entries
        XCTAssertEqual(entries[0].scope, "ui")
        XCTAssertEqual(entries[0].message, "Redesigned dashboard layout")
        XCTAssertEqual(entries[1].scope, "api")
        XCTAssertNil(entries[2].scope)
        XCTAssertEqual(entries[2].message, "Simple change without scope")
    }
}
