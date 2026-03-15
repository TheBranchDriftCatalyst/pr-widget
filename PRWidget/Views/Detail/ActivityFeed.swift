import SwiftUI
import CatalystSwift

struct ActivityFeed: View {
    let activities: [PRActivityItem]

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
        }
    }

    @ViewBuilder
    private func activityRow(_ item: PRActivityItem) -> some View {
        switch item.kind {
        case .comment(let comment):
            commentRow(comment, date: item.date)
        case .event(let event):
            eventRow(event)
        }
    }

    private func commentRow(_ comment: PRComment, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "text.bubble")
                    .scaledFont(size: 9)
                    .foregroundStyle(Catalyst.blue)
                Text(comment.author.login)
                    .scaledFont(size: 11, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Catalyst.foreground)
                Spacer()
                Text(date.relativeTimeString)
                    .scaledFont(size: 10, design: .monospaced)
                    .foregroundStyle(Catalyst.subtle)
            }

            Text(comment.body.prefix(200))
                .scaledFont(size: 12)
                .foregroundStyle(Catalyst.muted)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
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
