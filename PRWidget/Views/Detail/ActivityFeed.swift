import SwiftUI
import CatalystSwift

struct ActivityFeed: View {
    let activities: [PRActivityItem]
    var onAddComment: ((String) async throws -> Void)? = nil

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

    private func replySection(onAddComment: @escaping (String) async throws -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .scaledFont(size: 9)
                    .foregroundStyle(Catalyst.cyan)
                Text("ADD COMMENT")
                    .scaledFont(size: 10, weight: .bold, design: .monospaced)
                    .tracking(1)
                    .foregroundStyle(Catalyst.muted)
            }
            CommentComposer(onSubmit: onAddComment)
                .background(Catalyst.cyan.opacity(0.05))
                .overlay(
                    Rectangle().fill(Catalyst.cyan).frame(width: 2),
                    alignment: .leading
                )
        }
    }

    @ViewBuilder
    private func activityRow(_ item: PRActivityItem) -> some View {
        switch item.kind {
        case .comment(let comment):
            collapsibleCommentRow(
                author: comment.author.login,
                body: comment.body,
                date: item.date,
                dimmed: comment.isMinimized,
                iconColor: Catalyst.blue
            )
        case .event(let event):
            if event.hasBody {
                collapsibleCommentRow(
                    author: event.actor?.login ?? "Someone",
                    body: event.body ?? "",
                    date: event.createdAt,
                    dimmed: false,
                    iconColor: iconColor(for: event.type),
                    titleSuffix: event.type == .reviewed ? reviewActionLabel(event.description) : nil
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
        author: String,
        body: String,
        date: Date,
        dimmed: Bool,
        iconColor: Color,
        titleSuffix: String? = nil
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
            Text(body)
                .scaledFont(size: 12)
                .foregroundStyle(Catalyst.muted)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
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
