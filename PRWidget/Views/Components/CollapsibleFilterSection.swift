import SwiftUI
import CatalystSwift

struct CollapsibleFilterSection: View {
    let icon: String
    let title: String
    let items: [String]
    @Binding var selected: Set<String>
    @Binding var excluded: Set<String>
    var accentColor: Color = Catalyst.yellow

    @State private var isExpanded = false

    private var activeFilterCount: Int {
        selected.count + excluded.count
    }

    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .scaledFont(size: 9)
                            .foregroundStyle(hasActiveFilters ? accentColor : Catalyst.subtle)

                        Text(title)
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .tracking(0.5)
                            .foregroundStyle(Catalyst.muted)

                        if hasActiveFilters {
                            CountBadge(count: activeFilterCount, color: accentColor)
                                .scaledFont(size: 9, weight: .medium, design: .monospaced)
                        }

                        Spacer()

                        if hasActiveFilters {
                            Button {
                                selected.removeAll()
                                excluded.removeAll()
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
                    itemGrid
                }
            }
        }
    }

    private var itemGrid: some View {
        FlowLayout(spacing: 4) {
            ForEach(items, id: \.self) { item in
                ToggleChip(
                    name: item,
                    state: chipState(for: item),
                    onTap: { cmdDown in
                        handleChipTap(item: item, cmdDown: cmdDown)
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Catalyst.card)
    }

    private func chipState(for item: String) -> ChipState {
        if selected.contains(item) { return .included }
        if excluded.contains(item) { return .excluded }
        return .inactive
    }

    private func handleChipTap(item: String, cmdDown: Bool) {
        let current = chipState(for: item)
        selected.remove(item)
        excluded.remove(item)

        switch (current, cmdDown) {
        case (.inactive, false):
            selected.insert(item)
        case (.inactive, true):
            excluded.insert(item)
        case (.included, false):
            break
        case (.included, true):
            excluded.insert(item)
        case (.excluded, true):
            break
        case (.excluded, false):
            selected.insert(item)
        }
    }
}
