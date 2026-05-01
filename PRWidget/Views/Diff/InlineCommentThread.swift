import SwiftUI
import CatalystSwift

struct InlineCommentThread: View {
    let thread: PRReviewThread
    var onReply: (String) async throws -> Void

    private var previewText: String {
        let body = thread.comments.first?.body ?? ""
        return String(body.prefix(80))
    }

    var body: some View {
        CollapsibleCommentBlock(
            accentColor: thread.isResolved ? Catalyst.subtle : Catalyst.blue,
            backgroundColor: thread.isResolved ? Catalyst.subtle.opacity(0.03) : Catalyst.blue.opacity(0.05),
            dimmed: thread.isResolved,
            initiallyExpanded: !thread.isResolved
        ) {
            threadHeader
        } expanded: {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(thread.comments) { comment in
                    commentRow(comment)
                    if comment.id != thread.comments.last?.id {
                        Divider().opacity(0.3)
                    }
                }

                CommentComposer(onSubmit: onReply)
            }
        }
    }

    private var threadHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: thread.isResolved ? "checkmark.circle.fill" : "circle")
                .scaledFont(size: 11)
                .foregroundStyle(thread.isResolved ? Catalyst.cyan : Catalyst.blue)
                .help(thread.isResolved ? "Resolved" : "Unresolved")

            Text("\(thread.comments.count) comment\(thread.comments.count == 1 ? "" : "s")")
                .scaledFont(size: 10, weight: .medium, design: .monospaced)
                .foregroundStyle(Catalyst.muted)

            if let firstAuthor = thread.comments.first?.author.login {
                Text("@\(firstAuthor):")
                    .scaledFont(size: 10, weight: .medium, design: .monospaced)
                    .foregroundStyle(Catalyst.muted)

                Text(previewText)
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.subtle)
                    .lineLimit(1)
                    .truncationMode(.tail)
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

            if let lastComment = thread.comments.last {
                Text(lastComment.createdAt.relativeTimeString)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
            }
        }
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
