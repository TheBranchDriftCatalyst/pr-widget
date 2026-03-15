import SwiftUI

/// A view modifier that applies a custom font size scaled by the `catalystScale` environment value.
///
/// Use this when you need a one-off font size that still respects the user's
/// scale preference but doesn't match any ``CatalystFontToken``.
///
/// ## Usage
///
/// ```swift
/// Text("Custom sized text")
///     .scaledFont(size: 18, weight: .bold, design: .monospaced)
/// ```
public struct ScaledFontModifier: ViewModifier {
    @Environment(\.catalystScale) private var scale

    /// The base point size before scaling.
    let size: CGFloat
    /// The font weight.
    let weight: Font.Weight
    /// The font design.
    let design: Font.Design

    /// Creates a scaled font modifier.
    /// - Parameters:
    ///   - size: The base point size (will be multiplied by `catalystScale`).
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - design: The font design. Defaults to `.default`.
    public init(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) {
        self.size = size
        self.weight = weight
        self.design = design
    }

    public func body(content: Content) -> some View {
        content
            .font(.system(size: size * scale, weight: weight, design: design))
    }
}

extension View {
    /// Applies a custom font size that scales with the `catalystScale` environment value.
    ///
    /// - Parameters:
    ///   - size: The base point size.
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - design: The font design. Defaults to `.default`.
    /// - Returns: A view with the scaled font applied.
    public func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design))
    }
}
