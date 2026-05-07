import SwiftUI
import CatalystSwift

struct ActivityFeed: View {
    let activities: [PRActivityItem]
    var onAddComment: ((String) async throws -> Void)? = nil

    @State private var bottomComposerExpanded = false
    @State private var replyingToItemId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "ACTIVITY")
                .padding(.bottom, 4)

            if activities.isEmpty {
                Text("No activity yet")
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.subtle)
            } else {
                ForEach(activities) { item in
                    activityRow(item)
                    if replyingToItemId == item.id, let onAddComment {
                        perCommentComposer(for: item, onAddComment: onAddComment)
                    }
                    if item.id != activities.last?.id {
                        GlowDivider()
                    }
                }
            }

            if let onAddComment {
                GlowDivider()
                    .padding(.vertical, 4)
                replySection(onAddComment: onAddComment)
            }
        }
    }

    private func perCommentComposer(
        for item: PRActivityItem,
        onAddComment: @escaping (String) async throws -> Void
    ) -> some View {
        let author = quotedAuthor(for: item)
        let originalBody = quotedBody(for: item)
        return CommentComposer { body in
            let composed = composeQuotedReply(author: author, original: originalBody, reply: body)
            try await onAddComment(composed)
            replyingToItemId = nil
        }
        .padding(.leading, 14)
        .background(Catalyst.cyan.opacity(0.04))
        .overlay(
            Rectangle().fill(Catalyst.cyan.opacity(0.6)).frame(width: 2),
            alignment: .leading
        )
    }

    /// Build a reply that quotes the original comment as a markdown blockquote
    /// so the relationship is visible on GitHub (which has no native threading
    /// for top-level PR comments).
    private func composeQuotedReply(author: String?, original: String, reply: String) -> String {
        let quoted = original
            .components(separatedBy: "\n")
            .map { "> \($0)" }
            .joined(separator: "\n")
        let header = author.map { "> **@\($0)** wrote:\n>\n" } ?? ""
        return "\(header)\(quoted)\n\n\(reply)"
    }

    private func quotedAuthor(for item: PRActivityItem) -> String? {
        switch item.kind {
        case .comment(let c): return c.author.login
        case .event(let e): return e.actor?.login
        }
    }

    private func quotedBody(for item: PRActivityItem) -> String {
        switch item.kind {
        case .comment(let c): return c.body
        case .event(let e): return e.body ?? ""
        }
    }

    @ViewBuilder
    private func replySection(onAddComment: @escaping (String) async throws -> Void) -> some View {
        if bottomComposerExpanded {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .scaledFont(size: 9)
                        .foregroundStyle(Catalyst.cyan)
                    Text("REPLY TO PR")
                        .scaledFont(size: 10, weight: .bold, design: .monospaced)
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
                CommentComposer { body in
                    try await onAddComment(body)
                    bottomComposerExpanded = false
                }
                .background(Catalyst.cyan.opacity(0.05))
                .overlay(
                    Rectangle().fill(Catalyst.cyan).frame(width: 2),
                    alignment: .leading
                )
            }
        } else {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    bottomComposerExpanded = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .scaledFont(size: 10)
                        .foregroundStyle(Catalyst.cyan)
                    Text("Reply to PR…")
                        .scaledFont(size: 11)
                        .foregroundStyle(Catalyst.subtle)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Catalyst.cyan.opacity(0.04), in: .rect(cornerRadius: Catalyst.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: Catalyst.radiusMD)
                        .strokeBorder(Catalyst.cyan.opacity(0.2), lineWidth: 0.5)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func activityRow(_ item: PRActivityItem) -> some View {
        switch item.kind {
        case .comment(let comment):
            collapsibleCommentRow(
                itemId: item.id,
                author: comment.author.login,
                body: comment.body,
                date: item.date,
                dimmed: comment.isMinimized,
                iconColor: Catalyst.blue,
                canReply: onAddComment != nil
            )
        case .event(let event):
            if event.hasBody {
                collapsibleCommentRow(
                    itemId: item.id,
                    author: event.actor?.login ?? "Someone",
                    body: event.body ?? "",
                    date: event.createdAt,
                    dimmed: false,
                    iconColor: iconColor(for: event.type),
                    titleSuffix: event.type == .reviewed ? reviewActionLabel(event.description) : nil,
                    canReply: onAddComment != nil
                )
            } else {
                eventRow(event)
            }
        }
    }

    /// Extract the action verb from a review description like "ClaPro commented".
    private func reviewActionLabel(_ desc: String) -> String? {
        let parts = desc.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        return String(parts[1])
    }

    private func collapsibleCommentRow(
        itemId: String,
        author: String,
        body: String,
        date: Date,
        dimmed: Bool,
        iconColor: Color,
        titleSuffix: String? = nil,
        canReply: Bool
    ) -> some View {
        CollapsibleCommentBlock(
            accentColor: iconColor,
            backgroundColor: iconColor.opacity(0.05),
            dimmed: dimmed,
            initiallyExpanded: false
        ) {
            HStack(spacing: 6) {
                Image(systemName: "text.bubble.fill")
                    .scaledFont(size: 10)
                    .foregroundStyle(iconColor)

                Text(author)
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)

                if let titleSuffix {
                    Text(titleSuffix)
                        .scaledFont(size: 10, weight: .medium, design: .monospaced)
                        .foregroundStyle(Catalyst.muted)
                }

                Text(body.prefix(80).replacingOccurrences(of: "\n", with: " "))
                    .scaledFont(size: 11)
                    .foregroundStyle(Catalyst.subtle)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(date.relativeTimeString)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
            }
        } expanded: {
            VStack(alignment: .leading, spacing: 4) {
                MarkdownText(text: body, fontSize: 12, foregroundColor: Catalyst.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if canReply {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                replyingToItemId = (replyingToItemId == itemId) ? nil : itemId
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .scaledFont(size: 9)
                                Text(replyingToItemId == itemId ? "Cancel" : "Reply")
                                    .scaledFont(size: 10, weight: .medium, design: .monospaced)
                            }
                            .foregroundStyle(replyingToItemId == itemId ? Catalyst.subtle : Catalyst.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (replyingToItemId == itemId ? Catalyst.subtle : Catalyst.cyan)
                                    .opacity(0.1),
                                in: .rect(cornerRadius: Catalyst.radiusSM)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Reply to this comment")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
    }

    private func eventRow(_ event: PRTimelineEvent) -> some View {
        HStack(spacing: 4) {
            eventIcon(event.type)
            Text(event.description)
                .scaledFont(size: 11, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
                .lineLimit(1)
            Spacer()
            Text(event.createdAt.relativeTimeString)
                .scaledFont(size: 10, design: .monospaced)
                .foregroundStyle(Catalyst.subtle)
        }
        .padding(.vertical, 2)
    }

    private func eventIcon(_ type: PRTimelineEventType) -> some View {
        Group {
            switch type {
            case .reviewed:
                Image(systemName: "eye.fill")
                    .foregroundStyle(Catalyst.cyan)
            case .commented:
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(Catalyst.blue)
            case .merged:
                Image(systemName: "arrow.triangle.merge")
                    .foregroundStyle(Catalyst.magenta)
            case .closed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Catalyst.red)
            case .reopened:
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .foregroundStyle(Catalyst.cyan)
            case .labeled:
                Image(systemName: "tag.fill")
                    .foregroundStyle(Catalyst.yellow)
            case .assigned:
                Image(systemName: "person.fill")
                    .foregroundStyle(Catalyst.blue)
            case .mentioned:
                Image(systemName: "at")
                    .foregroundStyle(Catalyst.pink)
            case .headRefForcePushed:
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(Catalyst.warning)
            }
        }
        .scaledFont(size: 9)
        .shadow(color: iconColor(for: type).opacity(0.5), radius: 2)
    }

    private func iconColor(for type: PRTimelineEventType) -> Color {
        switch type {
        case .reviewed: Catalyst.cyan
        case .commented: Catalyst.blue
        case .merged: Catalyst.magenta
        case .closed: Catalyst.red
        case .reopened: Catalyst.cyan
        case .labeled: Catalyst.yellow
        case .assigned: Catalyst.blue
        case .mentioned: Catalyst.pink
        case .headRefForcePushed: Catalyst.warning
        }
    }
}
