import SwiftUI
import CatalystSwift

enum ChipState {
    case inactive, included, excluded
}

struct ToggleChip: View {
    let name: String
    let state: ChipState
    let onTap: (_ cmdDown: Bool) -> Void

    var body: some View {
        Button {
            let cmdDown = NSEvent.modifierFlags.contains(.command)
            onTap(cmdDown)
        } label: {
            Text(name)
                .scaledFont(size: 9, weight: state == .inactive ? .medium : .bold, design: .monospaced)
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
        case .inactive: Catalyst.muted
        case .included: Catalyst.background
        case .excluded: Catalyst.background
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .inactive: Catalyst.surface
        case .included: Catalyst.yellow
        case .excluded: Catalyst.red
        }
    }

    private var borderColor: Color {
        switch state {
        case .inactive: Catalyst.border
        case .included: Color.clear
        case .excluded: Color.clear
        }
    }
}
