import Foundation

enum PRTimelineEventType: String, Sendable {
    case reviewed
    case commented
    case merged
    case closed
    case reopened
    case labeled
    case assigned
    case mentioned
    case headRefForcePushed
}

struct PRTimelineEvent: Identifiable, Hashable, Sendable {
    let id: String
    let type: PRTimelineEventType
    let actor: PRUser?
    let createdAt: Date
    let description: String
}
