import SwiftUI
import CatalystSwift

struct CommentComposer: View {
    var onSubmit: (String) async throws -> Void

    @State private var replyText = ""
    @State private var isSubmitting = false
    @State private var submitFailed = false
    @FocusState private var isFocused: Bool

    private var borderColor: Color {
        if submitFailed { return Catalyst.red.opacity(0.6) }
        if isFocused { return Catalyst.cyan.opacity(0.5) }
        return Catalyst.subtle.opacity(0.3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextEditor(text: $replyText)
                .scaledFont(size: 12)
                .scrollContentBackground(.hidden)
                .background(Catalyst.background.opacity(0.5))
                .frame(minHeight: 40, maxHeight: 80)
                .clipShape(.rect(cornerRadius: Catalyst.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
                .focused($isFocused)
                .disabled(isSubmitting)
                .onChange(of: replyText) { submitFailed = false }

            HStack {
                if submitFailed {
                    Text("Failed to submit")
                        .scaledFont(size: 10, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.red)
                }
                Spacer()
                Button {
                    guard !replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    isSubmitting = true
                    submitFailed = false
                    let text = replyText
                    Task {
                        do {
                            try await onSubmit(text)
                            replyText = ""
                        } catch {
                            submitFailed = true
                        }
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
                            .scaledFont(size: 11, weight: .medium, design: .monospaced)
                    }
                    .foregroundStyle(Catalyst.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Catalyst.subtle : Catalyst.cyan,
                        in: .rect(cornerRadius: Catalyst.radiusMD)
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
