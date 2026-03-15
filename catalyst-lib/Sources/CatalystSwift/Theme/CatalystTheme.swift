import SwiftUI

/// Catalyst cybersynthpunk dark theme — ported from catalyst-ui
public enum Catalyst {
    // MARK: - Core Surfaces
    public static let background = Color(red: 0.039, green: 0.039, blue: 0.059)  // #0a0a0f
    public static let card = Color(red: 0.086, green: 0.086, blue: 0.114)        // #16161d
    public static let surface = Color(red: 0.118, green: 0.118, blue: 0.141)     // #1e1e24
    public static let border = Color(red: 0.153, green: 0.153, blue: 0.165)      // #27272a

    // MARK: - Text
    public static let foreground = Color(red: 0.894, green: 0.894, blue: 0.906)  // #e4e4e7
    public static let muted = Color(red: 0.631, green: 0.631, blue: 0.667)       // #a1a1aa
    public static let subtle = Color(red: 0.400, green: 0.400, blue: 0.439)      // #66666f

    // MARK: - Neon Accents
    public static let cyan = Color(red: 0.0, green: 0.988, blue: 0.839)          // #00fcd6
    public static let magenta = Color(red: 0.753, green: 0.149, blue: 0.827)     // #c026d3
    public static let pink = Color(red: 1.0, green: 0.431, blue: 0.780)          // #ff6ec7
    public static let blue = Color(red: 0.0, green: 0.831, blue: 1.0)            // #00d4ff
    public static let red = Color(red: 1.0, green: 0.161, blue: 0.459)           // #ff2975
    public static let yellow = Color(red: 0.984, green: 0.749, blue: 0.141)      // #fbbf24

    // MARK: - Semantic
    public static let success = cyan
    public static let failure = red
    public static let warning = yellow
    public static let pending = Color(red: 0.0, green: 0.831, blue: 1.0)         // #00d4ff
    public static let destructive = red

    // MARK: - Glass Surface
    public static let glass = Color.white.opacity(0.03)

    // MARK: - Type Scale (unscaled — prefer .catalystFont(.token) for scale-aware usage)
    public static func display() -> Font { .system(size: 15, weight: .semibold) }
    public static func heading() -> Font { .system(size: 14, weight: .medium) }
    public static func subheading() -> Font { .system(size: 13, weight: .bold, design: .monospaced) }
    public static func body() -> Font { .system(size: 12, weight: .regular, design: .monospaced) }
    public static func caption() -> Font { .system(size: 11, weight: .medium, design: .monospaced) }
    public static func label() -> Font { .system(size: 10, weight: .bold, design: .monospaced) }
    public static func micro() -> Font { .system(size: 9, weight: .bold, design: .monospaced) }
    public static func nano() -> Font { .system(size: 8, weight: .bold, design: .monospaced) }

    // MARK: - Spacing Scale (4pt base unit)
    public static let spaceXS: CGFloat = 2
    public static let spaceSM: CGFloat = 4
    public static let spaceMD: CGFloat = 8
    public static let spaceLG: CGFloat = 12
    public static let spaceXL: CGFloat = 16
    public static let space2XL: CGFloat = 24

    // MARK: - Corner Radius
    public static let radiusSM: CGFloat = 3
    public static let radiusMD: CGFloat = 8
    @available(*, deprecated, renamed: "radiusMD")
    public static let cornerRadius: CGFloat = 8
    public static let radiusFull: CGFloat = 999

    // MARK: - Border Width
    public static let borderThin: CGFloat = 0.5
    public static let borderRegular: CGFloat = 1
    public static let borderThick: CGFloat = 2

    // MARK: - Animation Durations
    public static let animInstant: Double = 0.1
    public static let animFast: Double = 0.15
    public static let animNormal: Double = 0.25
    public static let animSlow: Double = 0.5
    public static let animPulse: Double = 3.0

    // MARK: - Tracking (Letter Spacing)
    public static let trackingHeader: CGFloat = 2
    public static let trackingLabel: CGFloat = 1
    public static let trackingChip: CGFloat = 0.5

    // MARK: - Glow Shadows (NSShadow-compatible values)
    public static let glowCyan = Color(red: 0.0, green: 0.988, blue: 0.839).opacity(0.4)
    public static let glowMagenta = Color(red: 0.753, green: 0.149, blue: 0.827).opacity(0.35)

    // MARK: - Gradient Helpers

    public static func neonGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    public static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [card, surface.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
