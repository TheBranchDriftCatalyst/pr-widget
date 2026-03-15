import SwiftUI

public struct CatalystScaleKey: EnvironmentKey {
    public static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    public var catalystScale: CGFloat {
        get { self[CatalystScaleKey.self] }
        set { self[CatalystScaleKey.self] = newValue }
    }
}
