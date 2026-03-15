import SwiftUI
import CatalystSwift

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(isFocused ? Catalyst.cyan : Catalyst.subtle)

            TextField("Search PRs...", text: $text)
                .textFieldStyle(.plain)
                .scaledFont(size: 12, design: .monospaced)
                .foregroundStyle(Catalyst.foreground)
                .focused($isFocused)
                .accessibilityIdentifier(AccessibilityID.searchField)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Catalyst.subtle)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.searchClearButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Catalyst.surface)
        .clipShape(.rect(cornerRadius: Catalyst.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Catalyst.cornerRadius)
                .strokeBorder(isFocused ? Catalyst.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .if(isFocused) { $0.neonGlow(Catalyst.cyan, radius: 4) }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Catalyst.card)
        .accessibilityIdentifier(AccessibilityID.searchBar)
    }
}
