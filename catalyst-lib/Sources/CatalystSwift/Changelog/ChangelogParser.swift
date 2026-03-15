import Foundation

// MARK: - Models

public struct ChangelogRelease: Identifiable, Sendable {
    public let id: String
    public let version: String
    public let date: String?
    public let sections: [ChangelogSection]

    public init(version: String, date: String?, sections: [ChangelogSection]) {
        self.id = version
        self.version = version
        self.date = date
        self.sections = sections
    }
}

public struct ChangelogSection: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let entries: [ChangelogEntry]

    public init(title: String, entries: [ChangelogEntry]) {
        self.id = title
        self.title = title
        self.entries = entries
    }
}

public struct ChangelogEntry: Identifiable, Sendable {
    public let id: String
    public let scope: String?
    public let message: String
    public let isBreaking: Bool

    public init(scope: String?, message: String, isBreaking: Bool = false) {
        self.id = UUID().uuidString
        self.scope = scope
        self.message = message
        self.isBreaking = isBreaking
    }
}

// MARK: - Parser

public enum ChangelogParser {
    /// Parse a Keep a Changelog / git-cliff markdown string into releases.
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

    /// Convenience: load and parse CHANGELOG.md from a bundle.
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
