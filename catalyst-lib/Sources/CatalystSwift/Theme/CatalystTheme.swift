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

    // MARK: - Radius
    public static let cornerRadius: CGFloat = 8

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
