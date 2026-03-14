import SwiftUI
import CatalystSwift

struct AgingBoardView: View {
    let pullRequests: [PullRequest]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PR AGING BOARD")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Catalyst.cyan)

            ForEach(pullRequests) { pr in
                HStack {
                    Circle()
                        .fill(ageColor(pr.age))
                        .frame(width: 10, height: 10)
                        .shadow(color: ageColor(pr.age).opacity(0.5), radius: 3, x: 0, y: 0)
                    Text(pr.title)
                        .font(.caption)
                        .foregroundStyle(Catalyst.foreground)
                        .lineLimit(1)
                    Spacer()
                    Text(pr.ageText)
                        .font(.caption)
                        .fontDesign(.monospaced)
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
