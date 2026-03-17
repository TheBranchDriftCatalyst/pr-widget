import SwiftUI
import CatalystSwift

struct RequestChangesPopover: View {
    @Binding var comment: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "REQUEST CHANGES", accentColor: Catalyst.warning)
            TextField("Describe requested changes...", text: $comment, axis: .vertical)
                .lineLimit(3...6)
                .frame(width: 250)
                .scaledFont(size: 11, design: .monospaced)
            HStack {
                Spacer()
                Button("Submit", action: onSubmit)
                    .buttonStyle(.borderedProminent)
                    .tint(Catalyst.warning)
                    .controlSize(.small)
                    .disabled(comment.isEmpty)
            }
        }
        .padding()
        .background(Catalyst.card)
    }
}
