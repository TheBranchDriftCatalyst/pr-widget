import SwiftUI

/// A settings view that displays all help tips grouped by category.
///
/// Tips are grouped by their ``HelpTip/category`` string, with categories
/// appearing in first-occurrence order. Each row shows the tip's icon,
/// title, description, and keyboard shortcut (if present).
///
/// ## Usage
///
/// ```swift
/// HelpSettingsView(tips: [
///     HelpTip(id: "1", category: "Nav", title: "Toggle", description: "...", icon: "rectangle.on.rectangle"),
///     HelpTip(id: "2", category: "Nav", title: "Refresh", description: "...", shortcut: "Cmd+R", icon: "arrow.clockwise"),
/// ])
/// ```
public struct HelpSettingsView: View {
    /// The tips to display, grouped by category.
    public let tips: [HelpTip]

    /// Creates a help settings view.
    /// - Parameter tips: The array of help tips to display.
    public init(tips: [HelpTip]) {
        self.tips = tips
    }

    /// Ordered unique categories (preserving first-occurrence order)
    private var orderedCategories: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tip in tips {
            if seen.insert(tip.category).inserted {
                result.append(tip.category)
            }
        }
        return result
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(orderedCategories, id: \.self) { category in
                    let categoryTips = tips.filter { $0.category == category }
                    helpSection(category: category, tips: categoryTips)
                }
            }
            .padding(16)
        }
    }

    private func helpSection(category: String, tips: [HelpTip]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.uppercased())
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.cyan)

            VStack(spacing: 1) {
                ForEach(tips) { tip in
                    helpRow(tip: tip)
                }
            }
            .clipShape(.rect(cornerRadius: Catalyst.radiusMD))
        }
    }

    private func helpRow(tip: HelpTip) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tip.icon)
                .scaledFont(size: 12)
                .foregroundStyle(Catalyst.cyan)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundStyle(Catalyst.foreground)

                Text(tip.description)
                    .scaledFont(size: 10)
                    .foregroundStyle(Catalyst.muted)
                    .lineLimit(3)
            }

            Spacer()

            if let shortcut = tip.shortcut {
                Text(shortcut)
                    .scaledFont(size: 9, weight: .medium, design: .monospaced)
                    .foregroundStyle(Catalyst.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Catalyst.yellow.opacity(0.1), in: .rect(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Catalyst.surface)
    }
}
