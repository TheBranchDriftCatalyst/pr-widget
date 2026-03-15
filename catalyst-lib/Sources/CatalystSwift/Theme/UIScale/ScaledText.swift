import SwiftUI

/// A text view that automatically scales its font with the `catalystScale` environment value.
///
/// `CText` wraps SwiftUI's `Text` and applies a system font whose size is
/// multiplied by the current scale factor. Defaults to 12pt monospaced,
/// matching ``Catalyst/body()``.
///
/// ## Usage
///
/// ```swift
/// CText("Hello, Catalyst")
///
/// CText("Status", size: 14, weight: .bold)
///
/// CText("Timestamp", size: 10, weight: .medium, design: .default)
/// ```
public struct CText: View {
    @Environment(\.catalystScale) private var scale

    /// The text string to display.
    let content: String
    /// The base point size before scaling.
    var size: CGFloat
    /// The font weight.
    var weight: Font.Weight
    /// The font design.
    var design: Font.Design

    /// Creates a scaled text view.
    /// - Parameters:
    ///   - content: The text string to display.
    ///   - size: The base point size. Defaults to `12`.
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - design: The font design. Defaults to `.monospaced`.
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

/// A label view that automatically scales its font with the `catalystScale` environment value.
///
/// `CLabel` wraps SwiftUI's `Label` (title + system image) and applies a
/// scaled system font. Defaults to 12pt monospaced.
///
/// ## Usage
///
/// ```swift
/// CLabel("Merge", systemImage: "arrow.merge")
///
/// CLabel("Warning", systemImage: "exclamationmark.triangle", size: 11, weight: .bold)
/// ```
public struct CLabel: View {
    @Environment(\.catalystScale) private var scale

    /// The label title.
    let title: String
    /// The SF Symbol name.
    let systemImage: String
    /// The base point size before scaling.
    var size: CGFloat
    /// The font weight.
    var weight: Font.Weight
    /// The font design.
    var design: Font.Design

    /// Creates a scaled label view.
    /// - Parameters:
    ///   - title: The label title text.
    ///   - systemImage: The SF Symbol name.
    ///   - size: The base point size. Defaults to `12`.
    ///   - weight: The font weight. Defaults to `.regular`.
    ///   - design: The font design. Defaults to `.monospaced`.
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
