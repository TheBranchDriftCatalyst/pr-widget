import SwiftUI
import CatalystSwift

struct AuthorFilterView: View {
    let availableAuthors: [String]
    @Binding var selectedAuthors: Set<String>
    @Binding var excludedAuthors: Set<String>
    @State private var isExpanded = false

    private var activeFilterCount: Int {
        selectedAuthors.count + excludedAuthors.count
    }

    private var hasActiveFilters: Bool {
        activeFilterCount > 0
    }

    var body: some View {
        if !availableAuthors.isEmpty {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person")
                            .font(.system(size: 9))
                            .foregroundStyle(hasActiveFilters ? Catalyst.yellow : Catalyst.subtle)

                        Text("AUTHORS")
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
                                selectedAuthors.removeAll()
                                excludedAuthors.removeAll()
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
                    authorGrid
                }
            }
        }
    }

    private var authorGrid: some View {
        FlowLayout(spacing: 4) {
            ForEach(availableAuthors, id: \.self) { author in
                AuthorToggleChip(
                    name: author,
                    state: chipState(for: author),
                    onTap: { cmdDown in
                        handleChipTap(author: author, cmdDown: cmdDown)
                    }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Catalyst.card)
    }

    private func chipState(for author: String) -> AuthorChipState {
        if selectedAuthors.contains(author) { return .included }
        if excludedAuthors.contains(author) { return .excluded }
        return .unselected
    }

    private func handleChipTap(author: String, cmdDown: Bool) {
        let current = chipState(for: author)
        selectedAuthors.remove(author)
        excludedAuthors.remove(author)

        switch (current, cmdDown) {
        case (.unselected, false):
            selectedAuthors.insert(author)
        case (.unselected, true):
            excludedAuthors.insert(author)
        case (.included, false):
            break
        case (.included, true):
            excludedAuthors.insert(author)
        case (.excluded, true):
            break
        case (.excluded, false):
            selectedAuthors.insert(author)
        }
    }
}

private enum AuthorChipState {
    case unselected, included, excluded
}

private struct AuthorToggleChip: View {
    let name: String
    let state: AuthorChipState
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
