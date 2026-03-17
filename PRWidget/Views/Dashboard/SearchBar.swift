import SwiftUI
import CatalystSwift

struct SearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    /// Set to `true` from a parent (e.g. Cmd+F shortcut) to request focus.
    @Binding var requestFocus: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .scaledFont(size: 11)
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
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.subtle)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityID.searchClearButton)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Catalyst.surface)
        .clipShape(.rect(cornerRadius: Catalyst.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                .strokeBorder(isFocused ? Catalyst.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .shadow(color: isFocused ? Catalyst.cyan.opacity(0.4) : .clear, radius: isFocused ? 2 : 0)
        .shadow(color: isFocused ? Catalyst.cyan.opacity(0.4) : .clear, radius: isFocused ? 4 : 0)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Catalyst.card)
        .accessibilityIdentifier(AccessibilityID.searchBar)
        .onChange(of: requestFocus) {
            if requestFocus {
                isFocused = true
                requestFocus = false
            }
        }
    }
}
