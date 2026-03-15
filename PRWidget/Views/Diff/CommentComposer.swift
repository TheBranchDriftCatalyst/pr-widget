import SwiftUI
import CatalystSwift

struct CommentComposer: View {
    var onSubmit: (String) async -> Void

    @State private var replyText = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextEditor(text: $replyText)
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .background(Catalyst.background.opacity(0.5))
                .frame(minHeight: 40, maxHeight: 80)
                .clipShape(.rect(cornerRadius: Catalyst.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Catalyst.cornerRadius)
                        .strokeBorder(
                            isFocused ? Catalyst.cyan.opacity(0.5) : Catalyst.subtle.opacity(0.3),
                            lineWidth: 0.5
                        )
                )
                .focused($isFocused)

            HStack {
                Spacer()
                Button {
                    guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    isSubmitting = true
                    let text = replyText
                    replyText = ""
                    Task {
                        await onSubmit(text)
                        isSubmitting = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(Catalyst.background)
                        }
                        Text("Reply")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(Catalyst.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Catalyst.subtle : Catalyst.cyan,
                        in: .rect(cornerRadius: Catalyst.cornerRadius)
                    )
                }
                .buttonStyle(.plain)
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
