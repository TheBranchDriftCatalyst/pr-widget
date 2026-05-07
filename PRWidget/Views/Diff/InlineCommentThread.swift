import SwiftUI
import CatalystSwift

struct InlineCommentThread: View {
    let thread: PRReviewThread
    var onReply: (String) async throws -> Void

    @State private var replyingToCommentId: String?
    @State private var bottomComposerExpanded: Bool = false

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
                    if replyingToCommentId == comment.id {
                        perCommentComposer()
                    }
                    if comment.id != thread.comments.last?.id {
                        Divider().opacity(0.3)
                    }
                }

                bottomComposer()
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

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        replyingToCommentId = (replyingToCommentId == comment.id) ? nil : comment.id
                    }
                } label: {
                    Image(systemName: "arrowshape.turn.up.left")
                        .scaledFont(size: 10)
                        .foregroundStyle(replyingToCommentId == comment.id ? Catalyst.cyan : Catalyst.subtle)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(replyingToCommentId == comment.id ? "Cancel reply" : "Reply to this comment")
            }

            MarkdownText(text: comment.body, fontSize: 12, foregroundColor: Catalyst.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func perCommentComposer() -> some View {
        CommentComposer { body in
            try await onReply(body)
            replyingToCommentId = nil
        }
        .padding(.leading, 14)
        .background(Catalyst.cyan.opacity(0.04))
        .overlay(
            Rectangle().fill(Catalyst.cyan.opacity(0.6)).frame(width: 2),
            alignment: .leading
        )
    }

    @ViewBuilder
    private func bottomComposer() -> some View {
        Divider().opacity(0.3)
        if bottomComposerExpanded {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .scaledFont(size: 9)
                        .foregroundStyle(Catalyst.cyan)
                    Text("REPLY TO THREAD")
                        .scaledFont(size: 9, weight: .bold, design: .monospaced)
                        .tracking(1)
                        .foregroundStyle(Catalyst.muted)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            bottomComposerExpanded = false
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .scaledFont(size: 9)
                            .foregroundStyle(Catalyst.subtle)
                    }
                    .buttonStyle(.plain)
                    .help("Collapse")
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)

                CommentComposer(onSubmit: onReply)
            }
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    bottomComposerExpanded = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .scaledFont(size: 9)
                        .foregroundStyle(Catalyst.cyan)
                    Text("Reply to thread…")
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.subtle)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
