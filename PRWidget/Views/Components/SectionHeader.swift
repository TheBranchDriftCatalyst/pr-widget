import SwiftUI
import CatalystSwift

struct SectionHeader: View {
    let title: String
    var accentColor: Color = Catalyst.muted

    var body: some View {
        Text(title)
            .scaledFont(size: 10, weight: .bold, design: .monospaced)
            .tracking(1)
            .foregroundStyle(accentColor)
    }
}
