import SwiftUI

public enum CatalystFontToken: Sendable {
    case display, heading, subheading, body, caption, label, micro, nano

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

    var design: Font.Design {
        switch self {
        case .display, .heading: .default
        case .subheading, .body, .caption, .label, .micro, .nano: .monospaced
        }
    }
}

public struct CatalystFontModifier: ViewModifier {
    @Environment(\.catalystScale) private var scale
    let token: CatalystFontToken

    public func body(content: Content) -> some View {
        content.font(.system(size: token.size * scale, weight: token.weight, design: token.design))
    }
}

extension View {
    /// Apply a type scale token that respects catalystScale
    public func catalystFont(_ token: CatalystFontToken) -> some View {
        modifier(CatalystFontModifier(token: token))
    }
}
