import SwiftUI

public struct CText: View {
    @Environment(\.catalystScale) private var scale
    let content: String
    var size: CGFloat
    var weight: Font.Weight
    var design: Font.Design

    public init(_ content: String, size: CGFloat = 12, weight: Font.Weight = .regular, design: Font.Design = .monospaced) {
        self.content = content
        self.size = size
        self.weight = weight
        self.design = design
    }

    public var body: some View {
        Text(content)
            .font(.system(size: size * scale, weight: weight, design: design))
    }
}

public struct CLabel: View {
    @Environment(\.catalystScale) private var scale
    let title: String
    let systemImage: String
    var size: CGFloat
    var weight: Font.Weight
    var design: Font.Design

    public init(_ title: String, systemImage: String, size: CGFloat = 12, weight: Font.Weight = .regular, design: Font.Design = .monospaced) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.weight = weight
        self.design = design
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: size * scale, weight: weight, design: design))
    }
}
