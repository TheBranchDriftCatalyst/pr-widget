import SwiftUI
import CatalystSwift

struct LabelFilterView: View {
    let availableLabels: [String]
    @Binding var selectedLabels: Set<String>
    @Binding var excludedLabels: Set<String>
    @State private var isExpanded = false

    private var activeFilterCount: Int {
        selectedLabels.count + excludedLabels.count
    }

    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var body: some View {
        if !availableLabels.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tag")
                            .scaledFont(size: 9)
                            .foregroundStyle(hasActiveFilters ? Catalyst.yellow : Catalyst.subtle)

                        Text("LABELS")
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .tracking(0.5)
                            .foregroundStyle(Catalyst.muted)

                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .scaledFont(size: 9, weight: .medium, design: .monospaced)
                                .foregroundStyle(Catalyst.yellow)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Catalyst.yellow.opacity(0.15), in: Capsule())
                        }

                        Spacer()

                        if hasActiveFilters {
                            Button {
                                selectedLabels.removeAll()
                                excludedLabels.removeAll()
                            } label: {
                                Text("CLEAR")
                                    .scaledFont(size: 8, weight: .bold, design: .monospaced)
                                    .foregroundStyle(Catalyst.subtle)
                            }
                            .buttonStyle(.plain)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .scaledFont(size: 8, weight: .bold)
                            .foregroundStyle(Catalyst.subtle)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .glassCard()
                }
                .buttonStyle(.plain)

                if isExpanded {
                    GlowDivider()
                    labelGrid
                }
            }
        }
    }

    private var labelGrid: some View {
        FlowLayout(spacing: 4) {
            ForEach(availableLabels, id: \.self) { label in
                ToggleChip(
                    name: label,
                    state: chipState(for: label),
                    onTap: { cmdDown in
                        handleChipTap(label: label, cmdDown: cmdDown)
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Catalyst.card)
    }

    private func chipState(for label: String) -> ChipState {
        if selectedLabels.contains(label) { return .included }
        if excludedLabels.contains(label) { return .excluded }
        return .inactive
    }

    private func handleChipTap(label: String, cmdDown: Bool) {
        let current = chipState(for: label)
        // Remove from both sets first
        selectedLabels.remove(label)
        excludedLabels.remove(label)

        switch (current, cmdDown) {
        case (.inactive, false):
            selectedLabels.insert(label)
        case (.inactive, true):
            excludedLabels.insert(label)
        case (.included, false):
            break // back to inactive
        case (.included, true):
            excludedLabels.insert(label)
        case (.excluded, true):
            break // back to inactive
        case (.excluded, false):
            selectedLabels.insert(label)
        }
    }
}

// Simple flow layout for wrapping label chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
