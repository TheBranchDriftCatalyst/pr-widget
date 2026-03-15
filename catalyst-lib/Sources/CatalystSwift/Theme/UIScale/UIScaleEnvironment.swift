import SwiftUI

/// The SwiftUI environment key for the Catalyst UI scale factor.
///
/// The default value is `1.0` (100%). Set this at the root of your view
/// hierarchy to control the scale of all ``CatalystFontToken``-based text.
///
/// ## Usage
///
/// ```swift
/// ContentView()
///     .environment(\.catalystScale, 1.2) // 120% scale
/// ```
public struct CatalystScaleKey: EnvironmentKey {
    public static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    /// The current Catalyst UI scale factor.
    ///
    /// Read this value in views or modifiers that need to scale proportionally
    /// with the user's text size preference. Defaults to `1.0`.
    ///
    /// ```swift
    /// @Environment(\.catalystScale) private var scale
    /// ```
    public var catalystScale: CGFloat {
        get { self[CatalystScaleKey.self] }
        set { self[CatalystScaleKey.self] = newValue }
    }
}
