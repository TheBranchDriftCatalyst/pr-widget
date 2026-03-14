import SwiftUI
import CatalystSwift

struct LabelPill: View {
    let label: PRLabel

    var body: some View {
        Text(label.name)
            .font(.caption2)
            .fontWeight(.medium)
            .fontDesign(.monospaced)
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor, in: Capsule())
            .overlay(Capsule().strokeBorder(textColor.opacity(0.3), lineWidth: 0.5))
            .help(label.description ?? label.name)
    }

    private var backgroundColor: Color {
        Color(hex: label.color)?.opacity(0.15) ?? Catalyst.surface
    }

    private var textColor: Color {
        Color(hex: label.color) ?? Catalyst.muted
    }
}
