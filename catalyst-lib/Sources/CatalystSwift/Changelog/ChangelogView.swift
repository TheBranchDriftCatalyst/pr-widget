import SwiftUI

/// Expandable changelog viewer with Catalyst styling.
/// Renders parsed changelog releases as expandable cards.
public struct ChangelogView: View {
    public let releases: [ChangelogRelease]
    @State private var expandedVersions: Set<String>

    public init(releases: [ChangelogRelease]) {
        self.releases = releases
        // Expand the most recent release by default
        let initial: Set<String> = if let first = releases.first {
            [first.version]
        } else {
            []
        }
        _expandedVersions = State(initialValue: initial)
    }

    public var body: some View {
        if releases.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(releases) { release in
                        releaseCard(release)
                    }
                }
                .padding(16)
            }
            .catalystScrollbar()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 28))
                .foregroundStyle(Catalyst.subtle)

            Text("No Changelog Available")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Catalyst.muted)

            Text("A changelog will appear here when releases are published.")
                .font(.system(size: 11))
                .foregroundStyle(Catalyst.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func releaseCard(_ release: ChangelogRelease) -> some View {
        let isExpanded = expandedVersions.contains(release.version)

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedVersions.remove(release.version)
                    } else {
                        expandedVersions.insert(release.version)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Catalyst.cyan)
                        .frame(width: 12)

                    Text(release.version)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Catalyst.foreground)

                    if let date = release.date {
                        Text(date)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Catalyst.subtle)
                    }

                    Spacer()

                    let entryCount = release.sections.reduce(0) { $0 + $1.entries.count }
                    Text("\(entryCount) changes")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Catalyst.muted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Sections (when expanded)
            if isExpanded {
                GlowDivider()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(release.sections) { section in
                        sectionView(section)
                    }
                }
                .padding(12)
            }
        }
        .glassCard()
    }

    private func sectionView(_ section: ChangelogSection) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(sectionColor(section.title))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(section.entries) { entry in
                    entryView(entry)
                }
            }
        }
    }

    private func entryView(_ entry: ChangelogEntry) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(entry.isBreaking ? Catalyst.red : Catalyst.subtle)
                .frame(width: 4, height: 4)
                .padding(.top, 5)

            Group {
                if let scope = entry.scope {
                    Text("**\(scope):** \(entry.message)")
                } else {
                    Text(entry.message)
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(entry.isBreaking ? Catalyst.red : Catalyst.muted)

            Spacer()
        }
    }

    private func sectionColor(_ title: String) -> Color {
        switch title.lowercased() {
        case let t where t.contains("add") || t.contains("feature") || t.contains("new"):
            return Catalyst.cyan
        case let t where t.contains("fix") || t.contains("bug"):
            return Catalyst.red
        case let t where t.contains("perf") || t.contains("optim"):
            return Catalyst.yellow
        case let t where t.contains("refactor") || t.contains("change"):
            return Catalyst.blue
        case let t where t.contains("break") || t.contains("remov") || t.contains("deprecat"):
            return Catalyst.magenta
        case let t where t.contains("doc"):
            return Catalyst.pink
        default:
            return Catalyst.muted
        }
    }
}
