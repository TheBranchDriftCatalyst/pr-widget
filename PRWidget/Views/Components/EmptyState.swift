import SwiftUI
import CatalystSwift

struct EmptyState: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = Catalyst.subtle

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: icon)
                .scaledFont(size: 28)
                .foregroundStyle(iconColor)
            Text(title)
                .scaledFont(size: 12, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Catalyst.muted)
            if let subtitle {
                Text(subtitle)
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.subtle)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
