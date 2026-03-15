import Foundation

// MARK: - Models

/// A single changelog release, containing a version, optional date, and sections.
///
/// Produced by ``ChangelogParser/parse(_:)`` from a Keep a Changelog
/// or git-cliff markdown string.
public struct ChangelogRelease: Identifiable, Sendable {
    public let id: String

    /// The version string (e.g., `"0.4.0"`).
    public let version: String

    /// The release date string, if present (e.g., `"2025-01-15"`).
    public let date: String?

    /// The sections in this release (e.g., "Added", "Fixed").
    public let sections: [ChangelogSection]

    /// Creates a changelog release.
    /// - Parameters:
    ///   - version: The version string.
    ///   - date: An optional date string.
    ///   - sections: The changelog sections.
    public init(version: String, date: String?, sections: [ChangelogSection]) {
        self.id = version
        self.version = version
        self.date = date
        self.sections = sections
    }
}

/// A section within a changelog release (e.g., "Added", "Fixed", "Breaking Changes").
public struct ChangelogSection: Identifiable, Sendable {
    public let id: String

    /// The section title (e.g., `"Added"`, `"Fixed"`).
    public let title: String

    /// The entries in this section.
    public let entries: [ChangelogEntry]

    /// Creates a changelog section.
    /// - Parameters:
    ///   - title: The section heading.
    ///   - entries: The changelog entries.
    public init(title: String, entries: [ChangelogEntry]) {
        self.id = title
        self.title = title
        self.entries = entries
    }
}

/// A single entry within a changelog section.
public struct ChangelogEntry: Identifiable, Sendable {
    public let id: String

    /// An optional scope prefix (e.g., `"auth"`, `"dashboard"`).
    public let scope: String?

    /// The entry message text.
    public let message: String

    /// Whether this entry is a breaking change.
    public let isBreaking: Bool

    /// Creates a changelog entry.
    /// - Parameters:
    ///   - scope: An optional scope prefix.
    ///   - message: The entry message.
    ///   - isBreaking: Whether this is a breaking change. Defaults to `false`.
    public init(scope: String?, message: String, isBreaking: Bool = false) {
        self.id = UUID().uuidString
        self.scope = scope
        self.message = message
        self.isBreaking = isBreaking
    }
}

// MARK: - Parser

/// Parses Keep a Changelog / git-cliff markdown into structured release models.
///
/// The parser recognizes:
/// - `## [version] - date` release headers
/// - `### Section` section headers
/// - `- message` and `- **scope**: message` entries
/// - `**breaking**` / `**BREAKING**` / `[**breaking**]` prefixes
///
/// ## Usage
///
/// ```swift
/// let markdown = """
/// ## [0.4.0] - 2025-01-15
///
/// ### Added
/// - **dashboard**: New team view
/// - Real-time polling
///
/// ### Fixed
/// - **auth**: Token refresh bug
/// """
///
/// let releases = ChangelogParser.parse(markdown)
/// // releases[0].version == "0.4.0"
/// // releases[0].sections.count == 2
/// ```
public enum ChangelogParser {
    /// Parses a Keep a Changelog / git-cliff markdown string into releases.
    ///
    /// - Parameter markdown: The raw markdown string.
    /// - Returns: An array of ``ChangelogRelease`` values, ordered as they appear.
    public static func parse(_ markdown: String) -> [ChangelogRelease] {
        var releases: [ChangelogRelease] = []
        var currentVersion: String?
        var currentDate: String?
        var currentSections: [ChangelogSection] = []
        var currentSectionTitle: String?
        var currentEntries: [ChangelogEntry] = []

        func flushSection() {
            if let title = currentSectionTitle, !currentEntries.isEmpty {
                currentSections.append(ChangelogSection(title: title, entries: currentEntries))
            }
            currentSectionTitle = nil
            currentEntries = []
        }

        func flushRelease() {
            flushSection()
            if let version = currentVersion, !currentSections.isEmpty {
                releases.append(ChangelogRelease(version: version, date: currentDate, sections: currentSections))
            }
            currentVersion = nil
            currentDate = nil
            currentSections = []
        }

        let lines = markdown.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Release header: ## [version] - date  or  ## [version]
            if trimmed.hasPrefix("## ") {
                flushRelease()
                let headerContent = String(trimmed.dropFirst(3))
                let parsed = parseReleaseHeader(headerContent)
                currentVersion = parsed.version
                currentDate = parsed.date
                continue
            }

            // Section header: ### Added, ### Fixed, etc.
            if trimmed.hasPrefix("### ") {
                flushSection()
                currentSectionTitle = String(trimmed.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                continue
            }

            // Entry: - message or - **scope**: message
            if trimmed.hasPrefix("- ") {
                let entryText = String(trimmed.dropFirst(2))
                let entry = parseEntry(entryText)
                currentEntries.append(entry)
                continue
            }
        }

        flushRelease()
        return releases
    }

    /// Loads and parses `CHANGELOG.md` from a bundle.
    ///
    /// - Parameter bundle: The bundle containing the changelog resource. Defaults to `.main`.
    /// - Returns: Parsed releases, or an empty array if the file is missing.
    public static func fromBundle(_ bundle: Bundle = .main) -> [ChangelogRelease] {
        guard let url = bundle.url(forResource: "CHANGELOG", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parse(content)
    }

    // MARK: - Private

    private static func parseReleaseHeader(_ header: String) -> (version: String, date: String?) {
        // Match [version] optionally followed by - date or (date)
        var version = header
        var date: String?

        // Extract version from brackets
        if let openBracket = header.firstIndex(of: "["),
           let closeBracket = header.firstIndex(of: "]") {
            version = String(header[header.index(after: openBracket)..<closeBracket])
            let remainder = String(header[header.index(after: closeBracket)...])
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-— "))
                .trimmingCharacters(in: .whitespaces)
            if !remainder.isEmpty {
                date = remainder
            }
        }

        return (version, date)
    }

    private static func parseEntry(_ text: String) -> ChangelogEntry {
        var working = text
        var isBreaking = false

        // Check for breaking change markers
        let breakingPrefixes = ["**breaking** ", "**BREAKING** ", "[**breaking**] "]
        for prefix in breakingPrefixes {
            if working.hasPrefix(prefix) {
                isBreaking = true
                working = String(working.dropFirst(prefix.count))
                break
            }
        }

        // Check for **scope**: message pattern
        if working.hasPrefix("**") {
            let rest = String(working.dropFirst(2))
            if let endBold = rest.range(of: "**") {
                let scope = String(rest[rest.startIndex..<endBold.lowerBound])
                var message = String(rest[endBold.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
                if message.hasPrefix(":") {
                    message = String(message.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                if !message.isEmpty {
                    return ChangelogEntry(scope: scope, message: message, isBreaking: isBreaking)
                }
            }
        }

        return ChangelogEntry(scope: nil, message: working, isBreaking: isBreaking)
    }
}
