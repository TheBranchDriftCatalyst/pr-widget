import SwiftUI

/// The Catalyst cybersynthpunk dark theme — a centralized design token system.
///
/// `Catalyst` is the single source of truth for all visual constants in the
/// Catalyst ecosystem. Every color, font, spacing value, radius, and animation
/// duration is defined here as a static property or function.
///
/// ## Usage
///
/// ```swift
/// Text("Hello, Catalyst")
///     .font(Catalyst.heading())
///     .foregroundStyle(Catalyst.cyan)
///     .padding(Catalyst.spaceMD)
/// ```
///
/// - Note: This is a port of the catalyst-ui React/TypeScript design system
///   into native Swift, ensuring consistency across web and macOS apps.
public enum Catalyst {

    // MARK: - Core Surfaces

    /// The deepest background layer (`#0a0a0f`).
    ///
    /// Use for the main app window background.
    public static let background = Color(red: 0.039, green: 0.039, blue: 0.059)  // #0a0a0f

    /// Elevated card background (`#16161d`).
    ///
    /// Use for card surfaces that sit above the background.
    public static let card = Color(red: 0.086, green: 0.086, blue: 0.114)        // #16161d

    /// Interactive surface background (`#1e1e24`).
    ///
    /// Use for hoverable or selectable areas within cards.
    public static let surface = Color(red: 0.118, green: 0.118, blue: 0.141)     // #1e1e24

    /// Border and divider color (`#27272a`).
    ///
    /// Use for separators, card outlines, and visual boundaries.
    public static let border = Color(red: 0.153, green: 0.153, blue: 0.165)      // #27272a

    // MARK: - Text

    /// Primary text color (`#e4e4e7`).
    ///
    /// Use for headings and body text that needs maximum readability.
    public static let foreground = Color(red: 0.894, green: 0.894, blue: 0.906)  // #e4e4e7

    /// Secondary text color (`#a1a1aa`).
    ///
    /// Use for descriptions, labels, and supporting text.
    public static let muted = Color(red: 0.631, green: 0.631, blue: 0.667)       // #a1a1aa

    /// Tertiary text color (`#66666f`).
    ///
    /// Use for timestamps, hints, and low-priority information.
    public static let subtle = Color(red: 0.400, green: 0.400, blue: 0.439)      // #66666f

    // MARK: - Neon Accents

    /// Primary neon accent (`#00fcd6`).
    ///
    /// The signature Catalyst color — use for primary actions, links, and success states.
    public static let cyan = Color(red: 0.0, green: 0.988, blue: 0.839)          // #00fcd6

    /// Secondary neon accent (`#c026d3`).
    ///
    /// Use for badges, secondary highlights, and category indicators.
    public static let magenta = Color(red: 0.753, green: 0.149, blue: 0.827)     // #c026d3

    /// Tertiary neon accent (`#ff6ec7`).
    ///
    /// Use for decorative highlights and documentation-related indicators.
    public static let pink = Color(red: 1.0, green: 0.431, blue: 0.780)          // #ff6ec7

    /// Information accent (`#00d4ff`).
    ///
    /// Use for informational states and pending indicators.
    public static let blue = Color(red: 0.0, green: 0.831, blue: 1.0)            // #00d4ff

    /// Error and destructive accent (`#ff2975`).
    ///
    /// Use for errors, failures, breaking changes, and destructive actions.
    public static let red = Color(red: 1.0, green: 0.161, blue: 0.459)           // #ff2975

    /// Warning accent (`#fbbf24`).
    ///
    /// Use for caution states and keyboard shortcut displays.
    public static let yellow = Color(red: 0.984, green: 0.749, blue: 0.141)      // #fbbf24

    // MARK: - Semantic

    /// Semantic alias for positive outcomes. Maps to ``cyan``.
    public static let success = cyan

    /// Semantic alias for negative outcomes. Maps to ``red``.
    public static let failure = red

    /// Semantic alias for caution states. Maps to ``yellow``.
    public static let warning = yellow

    /// Semantic alias for in-progress states (`#00d4ff`).
    public static let pending = Color(red: 0.0, green: 0.831, blue: 1.0)         // #00d4ff

    /// Semantic alias for destructive actions. Maps to ``red``.
    public static let destructive = red

    // MARK: - Glass Surface

    /// Subtle white overlay for glass-morphism effects.
    ///
    /// Applied as an overlay on ``GlassCardModifier`` to create a frosted appearance.
    public static let glass = Color.white.opacity(0.03)

    // MARK: - Type Scale (unscaled — prefer .catalystFont(.token) for scale-aware usage)

    /// Display font (15pt, semibold, default design).
    ///
    /// The largest font in the type scale. Use for prominent titles.
    ///
    /// - Note: This returns an unscaled font. For dynamic scaling,
    ///   use `.catalystFont(.display)` instead.
    public static func display() -> Font { .system(size: 15, weight: .semibold) }

    /// Heading font (14pt, medium, default design).
    ///
    /// Use for section headings and card titles.
    public static func heading() -> Font { .system(size: 14, weight: .medium) }

    /// Subheading font (13pt, bold, monospaced).
    ///
    /// Use for emphasized labels and sub-section titles.
    public static func subheading() -> Font { .system(size: 13, weight: .bold, design: .monospaced) }

    /// Body font (12pt, regular, monospaced).
    ///
    /// The default text font for content and descriptions.
    public static func body() -> Font { .system(size: 12, weight: .regular, design: .monospaced) }

    /// Caption font (11pt, medium, monospaced).
    ///
    /// Use for secondary information, timestamps, and metadata.
    public static func caption() -> Font { .system(size: 11, weight: .medium, design: .monospaced) }

    /// Label font (10pt, bold, monospaced).
    ///
    /// Use for category labels, section headers, and chip text.
    public static func label() -> Font { .system(size: 10, weight: .bold, design: .monospaced) }

    /// Micro font (9pt, bold, monospaced).
    ///
    /// Use for very small badges and indicators.
    public static func micro() -> Font { .system(size: 9, weight: .bold, design: .monospaced) }

    /// Nano font (8pt, bold, monospaced).
    ///
    /// The smallest font in the type scale. Use sparingly for tiny labels.
    public static func nano() -> Font { .system(size: 8, weight: .bold, design: .monospaced) }

    // MARK: - Spacing Scale (4pt base unit)

    /// Extra-small spacing: 2pt.
    public static let spaceXS: CGFloat = 2

    /// Small spacing: 4pt.
    public static let spaceSM: CGFloat = 4

    /// Medium spacing: 8pt. The default padding and gap value.
    public static let spaceMD: CGFloat = 8

    /// Large spacing: 12pt.
    public static let spaceLG: CGFloat = 12

    /// Extra-large spacing: 16pt. Standard container padding.
    public static let spaceXL: CGFloat = 16

    /// Double extra-large spacing: 24pt. Major section breaks.
    public static let space2XL: CGFloat = 24

    // MARK: - Corner Radius

    /// Small corner radius: 3pt. For badges and small elements.
    public static let radiusSM: CGFloat = 3

    /// Medium corner radius: 8pt. For cards, buttons, and inputs.
    public static let radiusMD: CGFloat = 8

    /// Deprecated. Use ``radiusMD`` instead.
    @available(*, deprecated, renamed: "radiusMD")
    public static let cornerRadius: CGFloat = 8

    /// Full corner radius: 999pt. Creates pill shapes and circles.
    public static let radiusFull: CGFloat = 999

    // MARK: - Border Width

    /// Thin border: 0.5pt. For subtle outlines and hairline dividers.
    public static let borderThin: CGFloat = 0.5

    /// Regular border: 1pt. The default border width.
    public static let borderRegular: CGFloat = 1

    /// Thick border: 2pt. For emphasized outlines and focus rings.
    public static let borderThick: CGFloat = 2

    // MARK: - Animation Durations

    /// Instant animation: 0.1s. For micro-interactions and hovers.
    public static let animInstant: Double = 0.1

    /// Fast animation: 0.15s. For quick transitions.
    public static let animFast: Double = 0.15

    /// Normal animation: 0.25s. The default transition duration.
    public static let animNormal: Double = 0.25

    /// Slow animation: 0.5s. For deliberate, visible animations.
    public static let animSlow: Double = 0.5

    /// Pulse animation: 3.0s. For slow repeating animations and ambient effects.
    public static let animPulse: Double = 3.0

    // MARK: - Tracking (Letter Spacing)

    /// Header-level letter spacing: 2pt.
    public static let trackingHeader: CGFloat = 2

    /// Label-level letter spacing: 1pt.
    public static let trackingLabel: CGFloat = 1

    /// Chip-level letter spacing: 0.5pt.
    public static let trackingChip: CGFloat = 0.5

    // MARK: - Glow Shadows (NSShadow-compatible values)

    /// Cyan glow shadow at 40% opacity. For primary accent glows.
    public static let glowCyan = Color(red: 0.0, green: 0.988, blue: 0.839).opacity(0.4)

    /// Magenta glow shadow at 35% opacity. For secondary accent glows.
    public static let glowMagenta = Color(red: 0.753, green: 0.149, blue: 0.827).opacity(0.35)

    // MARK: - Gradient Helpers

    /// Creates a linear gradient from a neon color at full opacity to 60% opacity.
    ///
    /// Flows from leading to trailing edge.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Rectangle()
    ///     .fill(Catalyst.neonGradient(Catalyst.cyan))
    /// ```
    ///
    /// - Parameter color: The neon accent color to create the gradient from.
    /// - Returns: A leading-to-trailing linear gradient.
    public static func neonGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// A diagonal gradient from ``card`` to ``surface`` at 50% opacity.
    ///
    /// Used as the default background for ``GlassCardModifier``.
    public static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [card, surface.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
