import SwiftUI

// MARK: - Glass Card

/// Applies a glass-morphism card background with adaptive transparency.
///
/// The glass card uses a gradient background with a subtle white overlay,
/// rounded corners, and a thin border stroke. It automatically adapts for
/// users who prefer reduced transparency by falling back to a solid card color.
///
/// ## Usage
///
/// ```swift
/// VStack {
///     Text("Dashboard")
///         .font(Catalyst.heading())
///     Text("Content here")
///         .font(Catalyst.body())
/// }
/// .padding()
/// .glassCard()
/// ```
///
/// - Note: Respects `accessibilityReduceTransparency` environment value.
public struct GlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(reduceTransparency ? AnyShapeStyle(Catalyst.card) : AnyShapeStyle(Catalyst.cardGradient))
            .if(!reduceTransparency) { $0.overlay(Catalyst.glass.allowsHitTesting(false)) }
            .clipShape(.rect(cornerRadius: Catalyst.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                    .strokeBorder(Catalyst.border.opacity(0.5), lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - Neon Glow

/// Applies a double-layered neon glow shadow to the view.
///
/// Creates a radiant effect by stacking two shadows at different radii —
/// one at half the specified radius and one at full. Automatically disabled
/// when the user has enabled Reduce Motion.
///
/// ## Usage
///
/// ```swift
/// Image(systemName: "bolt.fill")
///     .foregroundStyle(Catalyst.cyan)
///     .neonGlow(Catalyst.cyan)
///
/// // Custom glow radius
/// Text("ALERT")
///     .neonGlow(Catalyst.red, radius: 12)
/// ```
///
/// - Note: Respects `accessibilityReduceMotion` environment value.
public struct NeonGlowModifier: ViewModifier {
    /// The neon color for the glow shadow.
    public let color: Color

    /// The outer glow radius. The inner glow uses half this value.
    public var radius: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a neon glow modifier.
    /// - Parameters:
    ///   - color: The color of the glow effect.
    ///   - radius: The outer shadow radius. Defaults to `8`.
    public init(color: Color, radius: CGFloat = 8) {
        self.color = color
        self.radius = radius
    }

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .shadow(color: color.opacity(0.4), radius: radius / 2)
                .shadow(color: color.opacity(0.4), radius: radius)
        }
    }
}

// MARK: - Glow Divider

/// A thin horizontal divider with a subtle cyan glow beneath it.
///
/// Renders a gradient line (transparent -> border -> transparent) with a soft
/// blurred glow offset below. Use as a section separator inside glass cards.
///
/// ## Usage
///
/// ```swift
/// VStack {
///     Text("Section A")
///     GlowDivider()
///     Text("Section B")
/// }
/// ```
public struct GlowDivider: View {
    public init() {}

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Catalyst.border, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            Rectangle()
                .fill(Catalyst.cyan.opacity(0.05))
                .frame(height: 1)
                .blur(radius: 1)
                .offset(y: 0.5)
        }
    }
}

// MARK: - Shimmer Loading

/// Overlays a sweeping shimmer gradient animation for loading states.
///
/// A translucent gradient band moves continuously from left to right across
/// the view, creating a skeleton-loading effect. Falls back to a static
/// subtle overlay when Reduce Motion is enabled.
///
/// ## Usage
///
/// ```swift
/// RoundedRectangle(cornerRadius: Catalyst.radiusMD)
///     .fill(Catalyst.surface)
///     .frame(height: 44)
///     .shimmerLoading()
/// ```
///
/// - Note: Respects `accessibilityReduceMotion` environment value.
public struct ShimmerLoadingModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func body(content: Content) -> some View {
        if reduceMotion {
            content.overlay(Color.white.opacity(0.03))
        } else {
            content.overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.05), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1.5
                        }
                    }
                }
                .clipped()
            )
        }
    }
}

// MARK: - Hover Glow

/// Adds a subtle background highlight that appears on hover.
///
/// When the cursor enters the view, a faint tinted background fades in.
/// Useful for interactive list rows, buttons, and clickable areas.
///
/// ## Usage
///
/// ```swift
/// HStack {
///     Text("Pull Request #42")
///     Spacer()
/// }
/// .padding()
/// .hoverGlow(Catalyst.cyan)
/// ```
public struct HoverGlowModifier: ViewModifier {
    /// The tint color shown on hover at 6% opacity.
    public let color: Color

    @State private var isHovering = false

    /// Creates a hover glow modifier.
    /// - Parameter color: The highlight color to show on hover.
    public init(color: Color) {
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .background(isHovering ? color.opacity(0.06) : Color.clear)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Gradient Accent Stripe

/// A 3pt-wide vertical gradient stripe with a glow shadow.
///
/// Commonly used as a leading accent on card rows to indicate category
/// or status. The gradient fades from full opacity at the top to 40%
/// at the bottom.
///
/// ## Usage
///
/// ```swift
/// HStack(spacing: 0) {
///     GradientAccentStripe(color: Catalyst.cyan)
///     Text("Ready to merge")
///         .padding(.horizontal, 12)
/// }
/// ```
public struct GradientAccentStripe: View {
    /// The accent color for the stripe gradient and glow.
    public let color: Color

    /// Creates a gradient accent stripe.
    /// - Parameter color: The accent color to use.
    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3)
            .shadow(color: color.opacity(0.5), radius: 4)
    }
}

// MARK: - Hover Tooltip

/// Displays a themed tooltip above the view on hover.
///
/// The tooltip uses a dark card background with a neon-tinted border,
/// accent-colored gradient overlay, and a downward-pointing arrow.
/// Animates in with a spring transition; uses opacity-only when
/// Reduce Motion is enabled.
///
/// ## Usage
///
/// ```swift
/// Button("Merge") { /* ... */ }
///     .catalystTooltip("Merge this pull request")
///
/// // Custom accent color
/// Image(systemName: "exclamationmark.triangle")
///     .catalystTooltip("Conflicts detected", accent: Catalyst.red)
/// ```
///
/// - Note: Respects `accessibilityReduceMotion` environment value.
public struct CatalystTooltipModifier: ViewModifier {
    /// The text displayed in the tooltip.
    public let text: String

    /// The accent color for the tooltip border and glow.
    public var accentColor: Color

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Creates a tooltip modifier.
    /// - Parameters:
    ///   - text: The tooltip message.
    ///   - accent: The accent color for the border tint. Defaults to ``Catalyst/cyan``.
    public init(text: String, accent: Color = Catalyst.cyan) {
        self.text = text
        self.accentColor = accent
    }

    public func body(content: Content) -> some View {
        content
            .onHover { hovering in
                if reduceMotion {
                    isHovering = hovering
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isHovering = hovering
                    }
                }
            }
            .overlay(alignment: .top) {
                if isHovering {
                    VStack(spacing: 0) {
                        Text(text)
                            .scaledFont(size: 10, weight: .semibold, design: .monospaced)
                            .foregroundStyle(Catalyst.foreground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                RoundedRectangle(cornerRadius: Catalyst.radiusSM)
                                    .fill(Catalyst.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Catalyst.radiusSM)
                                            .fill(
                                                LinearGradient(
                                                    colors: [accentColor.opacity(0.08), .clear],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Catalyst.radiusSM)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [accentColor.opacity(0.6), accentColor.opacity(0.15)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 0.75
                                            )
                                    )
                            }
                            .shadow(color: accentColor.opacity(0.25), radius: 8)
                            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                        // Arrow
                        TooltipArrow()
                            .fill(Catalyst.card)
                            .overlay(
                                TooltipArrow()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.15)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 0.75
                                    )
                            )
                            .frame(width: 10, height: 5)
                    }
                    .fixedSize()
                    .offset(y: -36)
                    .allowsHitTesting(false)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.85, anchor: .bottom)))
                    .zIndex(100)
                }
            }
    }
}

private struct TooltipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}

// MARK: - Themed Scrollbar

/// A custom `NSScroller` that renders a thin cyan-tinted knob on a transparent track.
///
/// The scrollbar knob is 6pt wide and drawn with a rounded rectangle in
/// ``Catalyst/cyan`` at 30% opacity. The track is fully transparent.
///
/// - Note: Use ``ScrollViewStyler`` or the `.catalystScrollbar()` modifier
///   to apply this to a `ScrollView`.
public final class CatalystScroller: NSScroller {
    /// Returns a fixed scroller width of 6pt regardless of control size or style.
    override public class func scrollerWidth(for controlSize: ControlSize, scrollerStyle: Style) -> CGFloat {
        6
    }

    /// Draws the scrollbar knob as a rounded rectangle in cyan at 30% opacity.
    override public func drawKnob() {
        let knobRect = rect(for: .knob)
        guard !knobRect.isEmpty else { return }
        let insetRect = knobRect.insetBy(dx: 1, dy: 1)
        guard insetRect.width > 0, insetRect.height > 0 else { return }
        let path = NSBezierPath(roundedRect: insetRect, xRadius: 2, yRadius: 2)
        NSColor(red: 0, green: 0.988, blue: 0.839, alpha: 0.3).setFill()
        path.fill()
    }

    /// Draws nothing — the scrollbar track is fully transparent.
    override public func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        // Transparent track
    }
}

final class ScrollViewFinderView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, let scrollView = enclosingScrollView else { return }
        scrollView.scrollerStyle = .overlay
        let scroller = CatalystScroller()
        scroller.scrollerStyle = .overlay
        scrollView.verticalScroller = scroller
    }
}

/// An `NSViewRepresentable` that injects ``CatalystScroller`` into the nearest `ScrollView`.
///
/// Place this as a background on a `ScrollView` to replace the default scrollbar
/// with the Catalyst-themed thin cyan scrollbar.
///
/// ## Usage
///
/// ```swift
/// ScrollView {
///     // content
/// }
/// .background(ScrollViewStyler())
/// ```
///
/// - Note: Prefer the `.catalystScrollbar()` modifier, which wraps this view.
public struct ScrollViewStyler: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        ScrollViewFinderView()
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - View Extensions

public extension View {

    /// Applies a glass-morphism card background.
    ///
    /// Adds a gradient background, glass overlay, rounded corners, and a thin
    /// border stroke. Automatically adapts for reduced transparency.
    ///
    /// ```swift
    /// VStack { Text("Card content") }
    ///     .padding()
    ///     .glassCard()
    /// ```
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    /// Applies a double-layered neon glow shadow.
    ///
    /// - Parameters:
    ///   - color: The glow color.
    ///   - radius: The outer glow radius. Defaults to `8`.
    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }

    /// Overlays a sweeping shimmer animation for loading states.
    func shimmerLoading() -> some View {
        modifier(ShimmerLoadingModifier())
    }

    /// Adds a subtle background highlight on hover.
    ///
    /// - Parameter color: The tint color to show at 6% opacity on hover.
    func hoverGlow(_ color: Color) -> some View {
        modifier(HoverGlowModifier(color: color))
    }

    /// Displays a themed tooltip above the view on hover.
    ///
    /// - Parameters:
    ///   - text: The tooltip message.
    ///   - accent: The accent color for the tooltip border. Defaults to ``Catalyst/cyan``.
    func catalystTooltip(_ text: String, accent: Color = Catalyst.cyan) -> some View {
        modifier(CatalystTooltipModifier(text: text, accent: accent))
    }

    /// Replaces the default scrollbar with a thin cyan-tinted Catalyst scrollbar.
    func catalystScrollbar() -> some View {
        background(ScrollViewStyler())
    }

    /// Conditionally applies a view transformation.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Text("Status")
    ///     .if(isActive) { $0.foregroundStyle(Catalyst.cyan) }
    /// ```
    ///
    /// - Parameters:
    ///   - condition: Whether to apply the transformation.
    ///   - transform: A closure that transforms the view when `condition` is `true`.
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
