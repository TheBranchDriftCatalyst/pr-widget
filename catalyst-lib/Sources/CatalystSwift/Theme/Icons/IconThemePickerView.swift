import AppKit
import SwiftUI

/// A settings view that shows side-by-side variant previews and allows selection.
public struct IconThemePickerView: View {
    @Bindable var manager: IconThemeManager

    public init(manager: IconThemeManager) {
        self.manager = manager
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ICON THEME")
                .scaledFont(size: 10, weight: .bold, design: .monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.muted)

            HStack(spacing: 12) {
                ForEach(manager.config.variants) { variant in
                    VariantCard(
                        variant: variant,
                        isSelected: manager.activeVariant == variant,
                        config: manager.config
                    ) {
                        manager.activeVariant = variant
                    }
                }
            }
        }
        .padding(10)
        .modifier(GlassCardModifier())
    }
}

// MARK: - Variant Card

private struct VariantCard: View {
    let variant: IconVariant
    let isSelected: Bool
    let config: IconThemeConfig
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Group {
                    if let nsImage = NSImage(named: config.appIconPreviewName(variant: variant)) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Catalyst.surface)
                            .overlay(
                                Text(variant.rawValue.uppercased())
                                    .scaledFont(size: 20, weight: .bold, design: .monospaced)
                                    .foregroundStyle(Catalyst.subtle)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(.rect(cornerRadius: Catalyst.radiusMD))

                Text(variant.displayName)
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundStyle(isSelected ? Catalyst.cyan : Catalyst.muted)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                    .fill(isSelected ? Catalyst.cyan.opacity(0.08) : Catalyst.glass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                    .strokeBorder(
                        isSelected ? Catalyst.cyan.opacity(0.6) : Catalyst.border.opacity(0.5),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .modifier(NeonGlowModifier(color: Catalyst.cyan, radius: isSelected ? 8 : 0))
        }
        .buttonStyle(.plain)
    }
}
