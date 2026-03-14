import SwiftUI
import CatalystSwift

struct RequestChangesPopover: View {
    @Binding var comment: String
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("REQUEST CHANGES")
                .font(.caption)
                .fontWeight(.bold)
                .fontDesign(.monospaced)
                .tracking(1)
                .foregroundStyle(Catalyst.warning)
            TextField("Describe requested changes...", text: $comment, axis: .vertical)
                .lineLimit(3...6)
                .frame(width: 250)
                .font(.caption)
                .fontDesign(.monospaced)
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
