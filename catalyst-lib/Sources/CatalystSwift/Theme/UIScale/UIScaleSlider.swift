import SwiftUI

/// A settings control that lets users adjust the Catalyst UI text scale.
///
/// Displays a labeled slider (80% to 140% in 5% steps), the current
/// percentage, a Reset button (visible when not at 100%), and a live
/// preview line showing the effect on sample text.
///
/// ## Usage
///
/// ```swift
/// struct SettingsView: View {
///     @Binding var scale: CGFloat
///
///     var body: some View {
///         UIScaleSlider(scale: $scale)
///     }
/// }
/// ```
///
/// - Note: You are responsible for persisting the scale value and injecting
///   it into the environment via `.environment(\.catalystScale, scale)`.
public struct UIScaleSlider: View {
    /// Binding to the current scale factor.
    @Binding public var scale: CGFloat

    /// Creates a UI scale slider.
    /// - Parameter scale: A binding to the scale factor (typically `1.0`).
    public init(scale: Binding<CGFloat>) {
        self._scale = scale
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Text Scale")
                    .scaledFont(size: 12, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)

                Spacer()

                Text("\(Int(scale * 100))%")
                    .scaledFont(size: 11, weight: .bold, design: .monospaced)
                    .foregroundStyle(Catalyst.cyan)
                    .monospacedDigit()

                if scale != 1.0 {
                    Button("Reset") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scale = 1.0
                        }
                    }
                    .controlSize(.mini)
                    .buttonStyle(.bordered)
                }
            }

            Slider(value: $scale, in: 0.8...1.4, step: 0.05)
                .tint(Catalyst.cyan)

            // Live preview
            Text("The quick brown fox jumps over the lazy dog")
                .scaledFont(size: 12, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
                .lineLimit(1)
        }
    }
}
