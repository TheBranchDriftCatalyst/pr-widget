import SwiftUI
import CatalystSwift

struct AgingBoardView: View {
    let pullRequests: [PullRequest]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PR AGING BOARD")
                .scaledFont(size: 13, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.cyan)

            ForEach(pullRequests) { pr in
                HStack {
                    NeonDot(color: ageColor(pr.age), size: 10)
                    Text(pr.title)
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.foreground)
                        .lineLimit(1)
                    Spacer()
                    Text(pr.ageText)
                        .scaledFont(size: 11, design: .monospaced)
                        .foregroundStyle(Catalyst.muted)
                }
            }
        }
        .padding()
    }

    private func ageColor(_ age: TimeInterval) -> Color {
        let hours = age / 3600
        if hours < 24 { return Catalyst.cyan }
        if hours < 48 { return Catalyst.yellow }
        if hours < 120 { return Catalyst.warning }
        return Catalyst.red
    }
}
