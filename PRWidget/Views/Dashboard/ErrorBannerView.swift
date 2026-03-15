import SwiftUI
import CatalystSwift

struct ErrorBannerView: View {
    let message: String
    @State private var pulseGlow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Catalyst.red)
                .shadow(color: Catalyst.red.opacity(pulseGlow ? 0.6 : 0.2), radius: pulseGlow ? 6 : 2)
                .onAppear {
                    guard !reduceMotion else {
                        pulseGlow = true
                        return
                    }
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulseGlow = true
                    }
                }
            Text(message)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(Catalyst.foreground)
                .lineLimit(2)
            Spacer()
        }
        .padding(10)
        .background(Catalyst.red.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Catalyst.red.opacity(0.3)),
            alignment: .bottom
        )
        .accessibilityIdentifier(AccessibilityID.errorBanner)
    }
}
