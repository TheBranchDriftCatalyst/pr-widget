import SwiftUI
import CatalystSwift

struct PRListView: View {
    let title: String
    let prs: [PullRequest]
    let accentColor: Color

    var body: some View {
        if !prs.isEmpty {
            Section {
                ForEach(prs) { pr in
                    PRRowView(pr: pr, accentColor: accentColor)
                    if pr.id != prs.last?.id {
                        GlowDivider()
                    }
                }
            } header: {
                sectionHeader
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
                .shadow(color: accentColor.opacity(0.5), radius: 3, x: 0, y: 0)
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.foreground)
            Text("\(prs.count)")
                .font(.caption)
                .fontWeight(.medium)
                .fontDesign(.monospaced)
                .foregroundStyle(accentColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 1)
                .background(accentColor.opacity(0.15), in: Capsule())
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassCard()
    }
}
