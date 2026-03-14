import SwiftUI
import CatalystSwift

struct TeamDashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.largeTitle)
                .foregroundStyle(Catalyst.magenta)
            Text("TEAM DASHBOARD")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Catalyst.foreground)
            Text("Coming in Phase 3")
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundStyle(Catalyst.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
