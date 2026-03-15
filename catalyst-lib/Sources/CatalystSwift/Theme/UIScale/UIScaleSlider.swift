import SwiftUI

public struct UIScaleSlider: View {
    @Binding public var scale: CGFloat

    public init(scale: Binding<CGFloat>) {
        self._scale = scale
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Text Scale")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Catalyst.foreground)

                Spacer()

                Text("\(Int(scale * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
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
                .font(.system(size: 12 * scale, design: .monospaced))
                .foregroundStyle(Catalyst.subtle)
                .lineLimit(1)
        }
    }
}
