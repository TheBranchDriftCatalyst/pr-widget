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
                            .font(.system(size: 9))
                            .foregroundStyle(hasActiveFilters ? Catalyst.yellow : Catalyst.subtle)

                        Text("LABELS")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(0.5)
                            .foregroundStyle(Catalyst.muted)

                        if hasActiveFilters {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
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
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Catalyst.subtle)
                            }
                            .buttonStyle(.plain)
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
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
                LabelToggleChip(
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

    private func chipState(for label: String) -> LabelChipState {
        if selectedLabels.contains(label) { return .included }
        if excludedLabels.contains(label) { return .excluded }
        return .unselected
    }

    private func handleChipTap(label: String, cmdDown: Bool) {
        let current = chipState(for: label)
        // Remove from both sets first
        selectedLabels.remove(label)
        excludedLabels.remove(label)

        switch (current, cmdDown) {
        case (.unselected, false):
            selectedLabels.insert(label)
        case (.unselected, true):
            excludedLabels.insert(label)
        case (.included, false):
            break // back to unselected
        case (.included, true):
            excludedLabels.insert(label)
        case (.excluded, true):
            break // back to unselected
        case (.excluded, false):
            selectedLabels.insert(label)
        }
    }
}

private enum LabelChipState {
    case unselected, included, excluded
}

private struct LabelToggleChip: View {
    let name: String
    let state: LabelChipState
    let onTap: (_ cmdDown: Bool) -> Void

    var body: some View {
        Button {
            let cmdDown = NSEvent.modifierFlags.contains(.command)
            onTap(cmdDown)
        } label: {
            Text(name)
                .font(.system(size: 9, weight: state == .unselected ? .medium : .bold, design: .monospaced))
                .strikethrough(state == .excluded)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(backgroundColor, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .if(state == .included) { $0.neonGlow(Catalyst.yellow, radius: 4) }
                .if(state == .excluded) { $0.neonGlow(Catalyst.red, radius: 4) }
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch state {
        case .unselected: Catalyst.muted
        case .included: Catalyst.background
        case .excluded: Catalyst.background
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .unselected: Catalyst.surface
        case .included: Catalyst.yellow
        case .excluded: Catalyst.red
        }
    }

    private var borderColor: Color {
        switch state {
        case .unselected: Catalyst.border
        case .included: Color.clear
        case .excluded: Color.clear
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
