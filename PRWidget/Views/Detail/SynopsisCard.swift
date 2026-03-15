import SwiftUI
import CatalystSwift

struct SynopsisCard: View {
    let synopsis: AISynopsis?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader(title: "AI SYNOPSIS", accentColor: Catalyst.cyan)

                Spacer()

                if let synopsis {
                    Text(synopsis.provider.rawValue.uppercased())
                        .scaledFont(size: 8, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.subtle)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Catalyst.surface, in: Capsule())
                        .shadow(color: Catalyst.cyan.opacity(0.2), radius: 2)
                }
            }

            if let synopsis {
                Text(synopsis.summary)
                    .scaledFont(size: 12)
                    .foregroundStyle(Catalyst.foreground)
                    .fixedSize(horizontal: false, vertical: true)

                if !synopsis.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(synopsis.actionItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .scaledFont(size: 11)
                                    .foregroundStyle(Catalyst.cyan)
                                Text(item)
                                    .scaledFont(size: 11)
                                    .foregroundStyle(Catalyst.muted)
                            }
                        }
                    }
                }

                if let reason = synopsis.urgencyReason {
                    Text(reason)
                        .scaledFont(size: 10, design: .monospaced)
                        .foregroundStyle(Catalyst.warning)
                }
            } else if isLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(Catalyst.cyan)
                    Text("Generating synopsis...")
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.subtle)
                }
                .shimmerLoading()
            } else {
                Text("No synopsis available")
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.subtle)
            }
        }
        .padding(10)
        .glassCard()
        .overlay(
            VStack {
                Rectangle()
                    .fill(Catalyst.neonGradient(Catalyst.cyan))
                    .frame(height: 1)
                    .shadow(color: Catalyst.cyan.opacity(0.3), radius: 2)
                Spacer()
            }
            .clipShape(.rect(cornerRadius: Catalyst.cornerRadius))
        )
    }
}
