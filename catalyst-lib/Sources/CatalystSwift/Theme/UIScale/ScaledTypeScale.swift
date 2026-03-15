import SwiftUI

/// A predefined font token in the Catalyst type scale.
///
/// Each token maps to a specific combination of size, weight, and design
/// that matches the static ``Catalyst`` type scale functions. When used
/// with ``CatalystFontModifier`` via the `.catalystFont(_:)` modifier,
/// the token's base size is multiplied by the current `catalystScale`
/// environment value.
///
/// ## Usage
///
/// ```swift
/// Text("Dashboard")
///     .catalystFont(.heading)
///
/// Text("12 open PRs")
///     .catalystFont(.body)
/// ```
public enum CatalystFontToken: Sendable {
    /// Display: 15pt, semibold, default design.
    case display
    /// Heading: 14pt, medium, default design.
    case heading
    /// Subheading: 13pt, bold, monospaced.
    case subheading
    /// Body: 12pt, regular, monospaced.
    case body
    /// Caption: 11pt, medium, monospaced.
    case caption
    /// Label: 10pt, bold, monospaced.
    case label
    /// Micro: 9pt, bold, monospaced.
    case micro
    /// Nano: 8pt, bold, monospaced.
    case nano

    /// The base point size for this token before scaling.
    var size: CGFloat {
        switch self {
        case .display: 15
        case .heading: 14
        case .subheading: 13
        case .body: 12
        case .caption: 11
        case .label: 10
        case .micro: 9
        case .nano: 8
        }
    }

    /// The font weight for this token.
    var weight: Font.Weight {
        switch self {
        case .display: .semibold
        case .heading: .medium
        case .subheading: .bold
        case .body: .regular
        case .caption: .medium
        case .label, .micro, .nano: .bold
        }
    }

    /// The font design for this token.
    var design: Font.Design {
        switch self {
        case .display, .heading: .default
        case .subheading, .body, .caption, .label, .micro, .nano: .monospaced
        }
    }
}

/// A view modifier that applies a ``CatalystFontToken`` with dynamic scaling.
///
/// Reads the `catalystScale` environment value and multiplies it with the
/// token's base size to produce the final font.
public struct CatalystFontModifier: ViewModifier {
    @Environment(\.catalystScale) private var scale

    /// The font token to apply.
    let token: CatalystFontToken

    public func body(content: Content) -> some View {
        content.font(.system(size: token.size * scale, weight: token.weight, design: token.design))
    }
}

extension View {
    /// Applies a Catalyst type scale token that respects the `catalystScale` environment value.
    ///
    /// This is the preferred way to set fonts in Catalyst apps, as it
    /// automatically scales with the user's text size preference.
    ///
    /// ```swift
    /// Text("Status")
    ///     .catalystFont(.caption)
    /// ```
    ///
    /// - Parameter token: The type scale token to apply.
    /// - Returns: A view with the scaled font applied.
    public func catalystFont(_ token: CatalystFontToken) -> some View {
        modifier(CatalystFontModifier(token: token))
    }
}
