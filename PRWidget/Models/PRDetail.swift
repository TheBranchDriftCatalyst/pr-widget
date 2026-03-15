import Foundation

struct PRDetail: Sendable {
    let comments: [PRComment]
    let timelineEvents: [PRTimelineEvent]
    let commits: [PRCommit]
    let checkRuns: [PRCheckRun]
    let changedFiles: Int
    let bodyText: String
    let reviewThreads: [PRReviewThread]

    var allActivity: [PRActivityItem] {
        var items: [PRActivityItem] = []

        for comment in comments {
            items.append(PRActivityItem(
                id: comment.id,
                date: comment.createdAt,
                kind: .comment(comment)
            ))
        }

        for event in timelineEvents {
            items.append(PRActivityItem(
                id: event.id,
                date: event.createdAt,
                kind: .event(event)
            ))
        }

        return items.sorted { $0.date < $1.date }
    }
}

struct PRActivityItem: Identifiable, Sendable {
    let id: String
    let date: Date
    let kind: Kind

    enum Kind: Sendable {
        case comment(PRComment)
        case event(PRTimelineEvent)
    }
}
