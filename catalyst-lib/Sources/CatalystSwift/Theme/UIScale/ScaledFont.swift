import SwiftUI

public struct ScaledFontModifier: ViewModifier {
    @Environment(\.catalystScale) private var scale
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

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
    public func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight, design: design))
    }
}
