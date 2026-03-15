import SwiftUI

/// Generic help tips view that groups tips by category string.
/// Preserves order of first occurrence for categories.
public struct HelpSettingsView: View {
    public let tips: [HelpTip]

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
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Catalyst.cyan)

            VStack(spacing: 1) {
                ForEach(tips) { tip in
                    helpRow(tip: tip)
                }
            }
            .clipShape(.rect(cornerRadius: 6))
        }
    }

    private func helpRow(tip: HelpTip) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tip.icon)
                .font(.system(size: 12))
                .foregroundStyle(Catalyst.cyan)
                .frame(width: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(tip.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Catalyst.foreground)

                Text(tip.description)
                    .font(.system(size: 10))
                    .foregroundStyle(Catalyst.muted)
                    .lineLimit(3)
            }

            Spacer()

            if let shortcut = tip.shortcut {
                Text(shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
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
