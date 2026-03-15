import SwiftUI
import CatalystSwift

struct InlineCommentThread: View {
    let thread: PRReviewThread
    var onReply: (String) async throws -> Void

    @State private var isExpanded: Bool

    init(thread: PRReviewThread, onReply: @escaping (String) async throws -> Void) {
        self.thread = thread
        self.onReply = onReply
        self._isExpanded = State(initialValue: !thread.isResolved)
    }

    private var previewText: String {
        let body = thread.comments.first?.body ?? ""
        return String(body.prefix(80))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thread header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .scaledFont(size: 8, weight: .bold)
                        .foregroundStyle(Catalyst.subtle)
                        .frame(width: 10)

                    Image(systemName: "text.bubble.fill")
                        .scaledFont(size: 10)
                        .foregroundStyle(thread.isResolved ? Catalyst.subtle : Catalyst.blue)

                    Text("\(thread.comments.count) comment\(thread.comments.count == 1 ? "" : "s")")
                        .scaledFont(size: 10, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.muted)

                    if !isExpanded, let firstAuthor = thread.comments.first?.author.login {
                        Text("@\(firstAuthor):")
                            .scaledFont(size: 10, weight: .medium, design: .monospaced)
                            .foregroundStyle(Catalyst.muted)

                        Text(previewText)
                            .scaledFont(size: 11)
                            .foregroundStyle(Catalyst.subtle)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    if thread.isResolved {
                        Text("RESOLVED")
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .foregroundStyle(Catalyst.subtle)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Catalyst.subtle.opacity(0.15), in: Capsule())
                    }

                    if thread.isOutdated {
                        Text("OUTDATED")
                            .scaledFont(size: 9, weight: .bold, design: .monospaced)
                            .foregroundStyle(Catalyst.yellow)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Catalyst.yellow.opacity(0.15), in: Capsule())
                    }

                    Spacer()

                    if !isExpanded, let lastComment = thread.comments.last {
                        Text(lastComment.createdAt.relativeTimeString)
                            .scaledFont(size: 10, design: .monospaced)
                            .foregroundStyle(Catalyst.subtle)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(thread.comments) { comment in
                        commentRow(comment)
                        if comment.id != thread.comments.last?.id {
                            Divider().opacity(0.3)
                        }
                    }

                    CommentComposer(onSubmit: onReply)
                }
                .padding(.leading, 20)
            }
        }
        .background(thread.isResolved ? Catalyst.subtle.opacity(0.03) : Catalyst.blue.opacity(0.05))
        .opacity(thread.isResolved ? 0.6 : 1.0)
        .overlay(
            Rectangle()
                .fill(thread.isResolved ? Catalyst.subtle : Catalyst.blue)
                .frame(width: 2),
            alignment: .leading
        )
    }

    private func commentRow(_ comment: PRReviewComment) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(comment.author.login)
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)

                Spacer()

                Text(comment.createdAt.relativeTimeString)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
            }

            Text(comment.body)
                .scaledFont(size: 12)
                .foregroundStyle(Catalyst.muted)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
