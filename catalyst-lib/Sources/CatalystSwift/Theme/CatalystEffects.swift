import SwiftUI

// MARK: - Glass Card

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

public struct NeonGlowModifier: ViewModifier {
    public let color: Color
    public var radius: CGFloat = 8
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

public struct HoverGlowModifier: ViewModifier {
    public let color: Color
    @State private var isHovering = false

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

public struct GradientAccentStripe: View {
    public let color: Color

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

public struct CatalystTooltipModifier: ViewModifier {
    public let text: String
    @State private var isHovering = false

    public init(text: String) {
        self.text = text
    }

    public func body(content: Content) -> some View {
        content
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .overlay(alignment: .top) {
                if isHovering {
                    Text(text)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Catalyst.foreground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Catalyst.surface, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Catalyst.border, lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .fixedSize()
                        .offset(y: -32)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
    }
}

// MARK: - Themed Scrollbar

public final class CatalystScroller: NSScroller {
    override public class func scrollerWidth(for controlSize: ControlSize, scrollerStyle: Style) -> CGFloat {
        6
    }

    override public func drawKnob() {
        let knobRect = rect(for: .knob)
        guard !knobRect.isEmpty else { return }
        let insetRect = knobRect.insetBy(dx: 1, dy: 1)
        guard insetRect.width > 0, insetRect.height > 0 else { return }
        let path = NSBezierPath(roundedRect: insetRect, xRadius: 2, yRadius: 2)
        NSColor(red: 0, green: 0.988, blue: 0.839, alpha: 0.3).setFill()
        path.fill()
    }

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

public struct ScrollViewStyler: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSView {
        ScrollViewFinderView()
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - View Extensions

public extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    func neonGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }

    func shimmerLoading() -> some View {
        modifier(ShimmerLoadingModifier())
    }

    func hoverGlow(_ color: Color) -> some View {
        modifier(HoverGlowModifier(color: color))
    }

    func catalystTooltip(_ text: String) -> some View {
        modifier(CatalystTooltipModifier(text: text))
    }

    func catalystScrollbar() -> some View {
        background(ScrollViewStyler())
    }

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
